defmodule TullnData.Budget.Vrv97Test do
  use ExUnit.Case, async: true

  alias TullnData.Budget.Vrv97

  @sample_path "priv/samples/vrv97_tulln_2018_finanzdaten.csv"

  describe "parse/1" do
    setup do
      csv = File.read!(@sample_path)
      entries = Vrv97.parse(csv)
      %{entries: entries, csv: csv}
    end

    test "parses all rows from sample file", %{entries: entries} do
      assert length(entries) == 1556
    end

    test "parses GKZ as string", %{entries: entries} do
      assert Enum.all?(entries, &(&1.gkz == "32135"))
    end

    test "parses year as integer", %{entries: entries} do
      assert Enum.all?(entries, &(&1.year == 2018))
    end

    test "parses budget type correctly", %{entries: entries} do
      first = hd(entries)
      assert first.budget_type == 1
      assert first.budget_type_name == "ordentliche Ausgaben"
      assert first.budget_type_atom == :ordinary_expenditures
    end

    test "contains all four budget types", %{entries: entries} do
      types = entries |> Enum.map(& &1.budget_type) |> Enum.uniq() |> Enum.sort()
      assert types == [1, 2, 5, 6]
    end

    test "parses functional and economic codes", %{entries: entries} do
      first = hd(entries)
      assert first.functional_code == "000"
      assert first.economic_code == "670"
    end

    test "parses German decimal amounts to Decimal", %{entries: entries} do
      first = hd(entries)
      assert %Decimal{} = first.amount
      assert Decimal.equal?(first.amount, Decimal.new("266.53"))
    end

    test "parses large amounts with thousand separators", %{entries: entries} do
      large = Enum.find(entries, &Decimal.gt?(&1.amount, Decimal.new("100000")))
      assert large != nil
    end

    test "handles ISO-8859-1 encoded text", %{entries: entries} do
      names = Enum.map(entries, & &1.functional_name)
      assert "Gewählte Gemeindeorgane" in names
    end

    test "returns maps with expected keys", %{entries: entries} do
      expected_keys = [
        :gkz,
        :year,
        :budget_type,
        :budget_type_name,
        :budget_type_atom,
        :functional_code,
        :functional_name,
        :economic_code,
        :account_name,
        :amount
      ]

      first = hd(entries)
      assert Enum.all?(expected_keys, &Map.has_key?(first, &1))
    end
  end
end
