defmodule TullnDataWeb.WmsProxyController do
  use TullnDataWeb, :controller

  alias TullnData.WmsProxy.Cache

  @upstreams %{
    "noe-ogd" => "https://sdi.noe.gv.at/at.gv.noe.geoserver/OGD/wms"
  }

  def proxy(conn, %{"upstream" => upstream_id}) do
    case Map.fetch(@upstreams, upstream_id) do
      {:ok, base_url} ->
        url = "#{base_url}?#{conn.query_string}"
        serve(conn, url)

      :error ->
        send_resp(conn, 404, "Unknown WMS upstream")
    end
  end

  defp serve(conn, url) do
    case Cache.get(url) do
      {:ok, body, content_type} ->
        respond(conn, 200, body, content_type, "HIT")

      :miss ->
        fetch_and_cache(conn, url)
    end
  end

  @max_concurrent 4

  @upstream_opts [
    decode_body: false,
    retry: false,
    receive_timeout: 15_000,
    connect_options: [timeout: 5_000],
    headers: [
      {"user-agent", "TullnData/0.1 (Phoenix WMS proxy; tulln civic-tech project)"}
    ]
  ]

  defp fetch_and_cache(conn, url) do
    case acquire_slot() do
      :ok ->
        try do
          do_fetch(conn, url)
        after
          release_slot()
        end

      :busy ->
        conn
        |> put_resp_header("retry-after", "2")
        |> put_resp_header("x-cache", "BUSY")
        |> send_resp(503, "Upstream concurrency cap reached")
    end
  end

  defp do_fetch(conn, url) do
    case Req.get(url, @upstream_opts) do
      {:ok, %{status: 200, body: body, headers: headers}} ->
        content_type = content_type_from(headers)
        Cache.put(url, body, content_type)
        respond(conn, 200, body, content_type, "MISS")

      {:ok, %{status: status, body: body, headers: headers}} ->
        respond(conn, status, body, content_type_from(headers), "BYPASS")

      {:error, _reason} ->
        send_resp(conn, 502, "Upstream WMS request failed")
    end
  end

  defp acquire_slot do
    case Cache.inflight_counter() do
      nil -> :ok
      counter -> cas_acquire(counter)
    end
  end

  defp cas_acquire(counter) do
    current = :atomics.get(counter, 1)

    cond do
      current >= @max_concurrent ->
        :busy

      :atomics.compare_exchange(counter, 1, current, current + 1) == :ok ->
        :ok

      true ->
        cas_acquire(counter)
    end
  end

  defp release_slot do
    case Cache.inflight_counter() do
      nil -> :ok
      counter -> :atomics.sub(counter, 1, 1)
    end
  end

  defp respond(conn, status, body, content_type, cache_state) do
    conn
    |> put_resp_header("cache-control", "public, max-age=86400")
    |> put_resp_header("x-cache", cache_state)
    |> put_resp_content_type(content_type)
    |> send_resp(status, body)
  end

  defp content_type_from(headers) do
    case Map.get(headers, "content-type", []) do
      [ct | _] -> ct
      _ -> "image/png"
    end
  end
end
