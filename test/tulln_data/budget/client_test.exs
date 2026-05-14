defmodule TullnData.Budget.ClientTest do
  use ExUnit.Case, async: true

  @moduletag :external

  alias TullnData.Budget.Client
  alias TullnData.Budget.Vrv97
  alias TullnData.Budget.Vrv2015

  describe "download_vrv97/2" do
    test "downloads 2018 finanzdaten for Tulln" do
      assert {:ok, body} = Client.download_vrv97(2018, "finanzdaten")
      assert byte_size(body) > 0

      entries = Vrv97.parse(body)
      assert length(entries) > 100
      assert hd(entries).gkz == "32135"
      assert hd(entries).year == 2018
    end

    test "returns CSV even for minimal data years" do
      assert {:ok, body} = Client.download_vrv97(2001, "haftungen")
      assert byte_size(body) > 0
    end
  end

  describe "download_vrv2015/4" do
    test "downloads 2024 fhh actuals for Tulln" do
      assert {:ok, body} = Client.download_vrv2015(2024, "fhh")
      assert byte_size(body) > 0

      entries = Vrv2015.parse(body)
      assert length(entries) > 100
      assert hd(entries).gkz == "32135"
      assert hd(entries).year == 2024
    end

    test "downloads 2024 ehh actuals for Tulln" do
      assert {:ok, body} = Client.download_vrv2015(2024, "ehh")
      assert byte_size(body) > 0

      entries = Vrv2015.parse(body)
      assert length(entries) > 0
      assert hd(entries).budget_component == :ergebnishaushalt
    end
  end
end
