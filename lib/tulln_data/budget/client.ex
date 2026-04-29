defmodule TullnData.Budget.Client do
  @moduledoc """
  HTTP client for downloading municipal budget CSVs from offenerhaushalt.at.

  Two download paths:
  - VRV97 (2001-2019): simple GET from vrv97.offenerhaushalt.at
  - VRV2015 (2020+): 3-step session/CSRF token exchange on www.offenerhaushalt.at
  """

  @tulln_slug "tulln-der-donau"
  @tulln_gkz "32135"

  @vrv97_base "https://vrv97.offenerhaushalt.at"
  @vrv2015_base "https://www.offenerhaushalt.at"

  @vrv97_types ~w(finanzdaten voranschlag rechnungsabschluss schulden haftungen)
  @vrv2015_haushalte ~w(fhh ehh vhh)
  @download_referer "#{@vrv2015_base}/gemeinde/#{@tulln_slug}/download"

  @doc """
  Downloads a VRV97 CSV for Tulln. Returns `{:ok, binary}` with ISO-8859-1 encoded CSV.

  ## Parameters
    - `year`: 2001-2019
    - `type`: one of #{inspect(@vrv97_types)}
  """
  def download_vrv97(year, type \\ "finanzdaten")
      when type in @vrv97_types and year in 2001..2019 do
    url = "#{@vrv97_base}/download/#{type}/top/#{@tulln_slug}/#{year}"

    case Req.get(url, decode_body: false, redirect: true) do
      {:ok, %{status: 200, body: body}} when byte_size(body) > 0 ->
        {:ok, body}

      {:ok, %{status: 200, body: ""}} ->
        {:error, :no_data}

      {:ok, %{status: status}} ->
        {:error, {:http_status, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Downloads a VRV2015 CSV for Tulln. Returns `{:ok, binary}` with UTF-8 encoded CSV.

  ## Parameters
    - `year`: 2020+
    - `haushalt`: one of #{inspect(@vrv2015_haushalte)}
    - `ra_va`: `"ra"` (Rechnungsabschluss/actuals) or `"va"` (Voranschlag/budget)
    - `origin`: `"gemeinde"` or `"statistik_at"`
  """
  def download_vrv2015(year, haushalt, ra_va \\ "ra", origin \\ "gemeinde")
      when haushalt in @vrv2015_haushalte and ra_va in ["ra", "va"] and year >= 2020 do
    with {:ok, cookies, csrf_token} <- fetch_session_and_token(),
         {:ok, cookies} <- fetch_download_token(cookies, csrf_token),
         {:ok, body} <- fetch_csv(cookies, csrf_token, year, haushalt, ra_va, origin) do
      {:ok, body}
    end
  end

  @doc """
  Downloads all available budget data for Tulln across all years.

  Returns `{:ok, results}` where results is a list of
  `{:vrv97 | :vrv2015, year, type/haushalt, {:ok, binary} | {:error, term}}` tuples.
  """
  def download_all(opts \\ []) do
    vrv97_years = Keyword.get(opts, :vrv97_years, 2001..2019)
    vrv2015_years = Keyword.get(opts, :vrv2015_years, 2020..2026)
    vrv97_type = Keyword.get(opts, :vrv97_type, "finanzdaten")

    vrv97_results =
      for year <- vrv97_years do
        result = download_vrv97(year, vrv97_type)
        {:vrv97, year, vrv97_type, result}
      end

    vrv2015_results =
      for year <- vrv2015_years, haushalt <- @vrv2015_haushalte do
        result = download_vrv2015(year, haushalt)
        {:vrv2015, year, haushalt, result}
      end

    {:ok, vrv97_results ++ vrv2015_results}
  end

  defp fetch_session_and_token do
    url = "#{@vrv2015_base}/gemeinde/#{@tulln_slug}/download"

    case Req.get(url, decode_body: false, redirect: true, max_redirects: 5) do
      {:ok, %{status: 200, body: body, headers: headers}} ->
        cookies = extract_cookies(headers)
        csrf_token = extract_csrf_token(body)

        if csrf_token do
          {:ok, cookies, csrf_token}
        else
          {:error, :csrf_token_not_found}
        end

      {:ok, %{status: status}} ->
        {:error, {:http_status, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp fetch_download_token(cookies, csrf_token) do
    url = "#{@vrv2015_base}/downloads/get-token"

    body = URI.encode_query(%{"foo" => "bar", "_token" => csrf_token})

    case Req.post(url,
           body: body,
           headers: post_headers(cookies),
           decode_body: false,
           redirect: false
         ) do
      {:ok, %{status: 200, headers: headers}} ->
        updated_cookies = merge_cookies(cookies, extract_cookies(headers))
        {:ok, updated_cookies}

      {:ok, %{status: status}} ->
        {:error, {:download_token, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp fetch_csv(cookies, csrf_token, year, haushalt, ra_va, origin) do
    url = "#{@vrv2015_base}/downloads/ghdByParams"

    body =
      URI.encode_query(%{
        "haushalt" => haushalt,
        "rechnungsabschluss" => ra_va,
        "year" => to_string(year),
        "origin" => origin,
        "gkz" => @tulln_gkz,
        "_token" => csrf_token
      })

    case Req.post(url,
           body: body,
           headers: post_headers(cookies),
           decode_body: false,
           redirect: false
         ) do
      {:ok, %{status: 200, body: csv_body}} when byte_size(csv_body) > 0 ->
        {:ok, csv_body}

      {:ok, %{status: 200, body: ""}} ->
        {:error, :no_data}

      {:ok, %{status: status}} ->
        {:error, {:download_csv, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp post_headers(cookies) do
    [
      {"content-type", "application/x-www-form-urlencoded"},
      {"cookie", cookies},
      {"referer", @download_referer},
      {"x-requested-with", "XMLHttpRequest"}
    ]
  end

  defp extract_cookies(headers) do
    headers
    |> Map.get("set-cookie", [])
    |> Enum.map(fn cookie ->
      cookie |> String.split(";") |> hd()
    end)
    |> Enum.join("; ")
  end

  defp merge_cookies(existing, new) do
    existing_map =
      existing
      |> String.split("; ")
      |> Enum.reject(&(&1 == ""))
      |> Map.new(fn pair ->
        case String.split(pair, "=", parts: 2) do
          [k, v] -> {k, v}
          [k] -> {k, ""}
        end
      end)

    new_map =
      new
      |> String.split("; ")
      |> Enum.reject(&(&1 == ""))
      |> Map.new(fn pair ->
        case String.split(pair, "=", parts: 2) do
          [k, v] -> {k, v}
          [k] -> {k, ""}
        end
      end)

    Map.merge(existing_map, new_map)
    |> Enum.map(fn {k, v} -> "#{k}=#{v}" end)
    |> Enum.join("; ")
  end

  defp extract_csrf_token(html) do
    case Regex.run(~r/name="_token"\s+value="([^"]+)"/, html) do
      [_, token] ->
        token

      nil ->
        case Regex.run(~r/value="([^"]+)"\s+name="_token"/, html) do
          [_, token] -> token
          nil -> nil
        end
    end
  end
end
