defmodule TullnData.Budget.Vrv97 do
  @moduledoc """
  Parser for VRV97-format municipal budget CSVs from offenerhaushalt.at.

  Covers fiscal years 2001-2019. Files are ISO-8859-1 encoded,
  semicolon-delimited, with German decimal format (comma separator).
  """

  alias TullnData.Budget.CSVParser

  @budget_types %{
    1 => :ordinary_expenditures,
    2 => :ordinary_revenues,
    5 => :extraordinary_expenditures,
    6 => :extraordinary_revenues
  }

  def budget_types, do: @budget_types

  @doc """
  Parses a VRV97 CSV binary (ISO-8859-1 or UTF-8) into a list of maps.

  Automatically converts ISO-8859-1 to UTF-8 if needed.
  """
  def parse(binary) when is_binary(binary) do
    binary
    |> ensure_utf8()
    |> CSVParser.parse_string(skip_headers: true)
    |> Enum.map(&row_to_map/1)
  end

  defp row_to_map([gkz, jahr, hinweis, hinweis_name, ansatz, ansatz_name, post, konto_name, soll]) do
    budget_type = String.to_integer(hinweis)

    %{
      gkz: gkz,
      year: String.to_integer(jahr),
      budget_type: budget_type,
      budget_type_name: hinweis_name,
      budget_type_atom: Map.get(@budget_types, budget_type),
      functional_code: ansatz,
      functional_name: ansatz_name,
      economic_code: post,
      account_name: konto_name,
      amount: parse_german_decimal(soll)
    }
  end

  defp ensure_utf8(binary) do
    if String.valid?(binary) do
      binary
    else
      :unicode.characters_to_binary(binary, :latin1)
    end
  end

  defp parse_german_decimal(""), do: Decimal.new("0")

  defp parse_german_decimal(str) do
    str
    |> String.replace(".", "")
    |> String.replace(",", ".")
    |> Decimal.new()
  end
end
