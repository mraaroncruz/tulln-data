defmodule TullnData.Budget.Vrv2015 do
  @moduledoc """
  Parser for VRV2015-format municipal budget CSVs from offenerhaushalt.at.

  Covers fiscal years 2020-present. Files are UTF-8 encoded,
  semicolon-delimited, with German decimal format (comma separator).
  Three budget components: fhh (Finanzierungshaushalt), ehh (Ergebnishaushalt),
  vhh (Vermogenshaushalt).
  """

  alias TullnData.Budget.CSVParser

  @doc """
  Parses a VRV2015 fhh/ehh CSV binary into a list of maps.

  These have 16 columns with a single `Wert` amount column.
  """
  def parse(binary) when is_binary(binary) do
    binary
    |> CSVParser.parse_string(skip_headers: true)
    |> Enum.map(&row_to_map/1)
  end

  defp row_to_map([
         jahr,
         bundesland,
         va_ra,
         datenquelle,
         gkz,
         gemeindename,
         haushalt,
         ansatz_uab,
         ansatz_ugl,
         konto_grp,
         konto_ugl,
         vorhabencode,
         mvag,
         ansatz_text,
         konto_text,
         wert
       ]) do
    %{
      year: String.to_integer(jahr),
      state: bundesland,
      statement_type: parse_statement_type(va_ra),
      data_source: datenquelle,
      gkz: gkz,
      municipality: gemeindename,
      budget_component: parse_budget_component(haushalt),
      functional_code: ansatz_uab,
      functional_subcode: ansatz_ugl,
      account_group: konto_grp,
      account_subgroup: konto_ugl,
      project_code: vorhabencode,
      mvag: mvag,
      functional_name: ansatz_text,
      account_name: konto_text,
      amount: parse_german_decimal(wert)
    }
  end

  # vhh (legacy) — 20 columns with balance-sheet fields instead of single Wert
  defp row_to_map([
         jahr,
         bundesland,
         va_ra,
         datenquelle,
         gkz,
         gemeindename,
         _haushalt,
         ansatz_uab,
         ansatz_ugl,
         konto_grp,
         konto_ugl,
         vorhabencode,
         mvag,
         ansatz_text,
         konto_text,
         endstand_vj,
         zugang,
         abgang,
         aenderung,
         endstand_rj
       ]) do
    build_vhh_row(
      jahr,
      bundesland,
      va_ra,
      datenquelle,
      gkz,
      gemeindename,
      ansatz_uab,
      ansatz_ugl,
      konto_grp,
      konto_ugl,
      vorhabencode,
      mvag,
      ansatz_text,
      konto_text,
      endstand_vj,
      zugang,
      abgang,
      aenderung,
      endstand_rj
    )
  end

  # vhh (2023+) — 23 columns: adds Id-Vhh, Sektor, Land between Vorhabencode and Mvag
  defp row_to_map([
         jahr,
         bundesland,
         va_ra,
         datenquelle,
         gkz,
         gemeindename,
         _haushalt,
         ansatz_uab,
         ansatz_ugl,
         konto_grp,
         konto_ugl,
         vorhabencode,
         _id_vhh,
         _sektor,
         _land,
         mvag,
         ansatz_text,
         konto_text,
         endstand_vj,
         zugang,
         abgang,
         aenderung,
         endstand_rj
       ]) do
    build_vhh_row(
      jahr,
      bundesland,
      va_ra,
      datenquelle,
      gkz,
      gemeindename,
      ansatz_uab,
      ansatz_ugl,
      konto_grp,
      konto_ugl,
      vorhabencode,
      mvag,
      ansatz_text,
      konto_text,
      endstand_vj,
      zugang,
      abgang,
      aenderung,
      endstand_rj
    )
  end

  defp build_vhh_row(
         jahr,
         bundesland,
         va_ra,
         datenquelle,
         gkz,
         gemeindename,
         ansatz_uab,
         ansatz_ugl,
         konto_grp,
         konto_ugl,
         vorhabencode,
         mvag,
         ansatz_text,
         konto_text,
         endstand_vj,
         zugang,
         abgang,
         aenderung,
         endstand_rj
       ) do
    %{
      year: String.to_integer(jahr),
      state: bundesland,
      statement_type: parse_statement_type(va_ra),
      data_source: datenquelle,
      gkz: gkz,
      municipality: gemeindename,
      budget_component: :vermogenshaushalt,
      functional_code: ansatz_uab,
      functional_subcode: ansatz_ugl,
      account_group: konto_grp,
      account_subgroup: konto_ugl,
      project_code: vorhabencode,
      mvag: mvag,
      functional_name: ansatz_text,
      account_name: konto_text,
      prior_year_balance: parse_german_decimal(endstand_vj),
      additions: parse_german_decimal(zugang),
      disposals: parse_german_decimal(abgang),
      adjustments: parse_german_decimal(aenderung),
      closing_balance: parse_german_decimal(endstand_rj)
    }
  end

  defp parse_statement_type("Rechnungsabschluss"), do: :actuals
  defp parse_statement_type("Voranschlag"), do: :budget
  defp parse_statement_type(other), do: other

  defp parse_budget_component("Finanzierungshaushalt"), do: :finanzierungshaushalt
  defp parse_budget_component("Ergebnishaushalt"), do: :ergebnishaushalt
  defp parse_budget_component("Vermögenshaushalt"), do: :vermogenshaushalt
  defp parse_budget_component(other), do: other

  defp parse_german_decimal(""), do: Decimal.new("0")

  defp parse_german_decimal(str) do
    str
    |> String.replace(".", "")
    |> String.replace(",", ".")
    |> Decimal.new()
  end
end
