defmodule TullnData.Budget.Vrv2015Test do
  use ExUnit.Case, async: true

  alias TullnData.Budget.Vrv2015

  @sample_path "priv/samples/vrv2015_tulln_2024_fhh_ra.csv"

  describe "parse/1" do
    setup do
      csv = File.read!(@sample_path)
      entries = Vrv2015.parse(csv)
      %{entries: entries, csv: csv}
    end

    test "parses all rows from sample file", %{entries: entries} do
      assert length(entries) == 3046
    end

    test "parses year as integer", %{entries: entries} do
      assert Enum.all?(entries, &(&1.year == 2024))
    end

    test "parses GKZ as string", %{entries: entries} do
      assert Enum.all?(entries, &(&1.gkz == "32135"))
    end

    test "parses state name", %{entries: entries} do
      assert Enum.all?(entries, &(&1.state == "Niederösterreich"))
    end

    test "parses statement type to atom", %{entries: entries} do
      first = hd(entries)
      assert first.statement_type == :actuals
    end

    test "parses budget component to atom", %{entries: entries} do
      first = hd(entries)
      assert first.budget_component == :finanzierungshaushalt
    end

    test "parses municipality name", %{entries: entries} do
      first = hd(entries)
      assert first.municipality == "Tulln an der Donau"
    end

    test "parses classification codes", %{entries: entries} do
      first = hd(entries)
      assert is_binary(first.functional_code)
      assert is_binary(first.functional_subcode)
      assert is_binary(first.account_group)
      assert is_binary(first.account_subgroup)
      assert is_binary(first.project_code)
      assert is_binary(first.mvag)
    end

    test "parses German decimal amounts to Decimal", %{entries: entries} do
      first = hd(entries)
      assert %Decimal{} = first.amount
      assert Decimal.equal?(first.amount, Decimal.new("2825319.23"))
    end

    test "handles negative amounts", %{entries: entries} do
      negative = Enum.find(entries, &Decimal.negative?(&1.amount))
      assert negative != nil
    end

    test "parses description texts", %{entries: entries} do
      first = hd(entries)
      assert is_binary(first.functional_name)
      assert is_binary(first.account_name)
      assert first.account_name == "Vorsteuer - Evidenz"
    end

    test "returns maps with expected keys", %{entries: entries} do
      expected_keys = [
        :year,
        :state,
        :statement_type,
        :data_source,
        :gkz,
        :municipality,
        :budget_component,
        :functional_code,
        :functional_subcode,
        :account_group,
        :account_subgroup,
        :project_code,
        :mvag,
        :functional_name,
        :account_name,
        :amount
      ]

      first = hd(entries)
      assert Enum.all?(expected_keys, &Map.has_key?(first, &1))
    end
  end
end
