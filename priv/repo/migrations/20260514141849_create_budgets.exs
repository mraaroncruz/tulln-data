defmodule TullnData.Repo.Migrations.CreateBudgets do
  use Ecto.Migration

  def change do
    create table(:budget_municipalities) do
      add :slug, :string, null: false
      add :name, :string, null: false
      add :gkz, :string, null: false
      add :population, :integer
      add :bezirk, :string
      add :bundesland, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:budget_municipalities, [:slug])
    create unique_index(:budget_municipalities, [:gkz])

    create table(:budget_fiscal_years) do
      add :municipality_id,
          references(:budget_municipalities, on_delete: :delete_all),
          null: false

      add :year, :integer, null: false
      add :vrv_version, :string, null: false
      add :statement_type, :string, null: false
      add :budget_component, :string, null: false, default: "none"
      add :source_url, :string
      add :ingested_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(
             :budget_fiscal_years,
             [:municipality_id, :year, :vrv_version, :statement_type, :budget_component],
             name: :budget_fiscal_years_uniq
           )

    create index(:budget_fiscal_years, [:municipality_id, :year])

    create table(:budget_line_items) do
      add :fiscal_year_id,
          references(:budget_fiscal_years, on_delete: :delete_all),
          null: false

      add :ansatz_code, :string, null: false
      add :ansatz_subcode, :string
      add :account_code, :string
      add :account_subcode, :string
      add :ansatz_name, :string
      add :account_name, :string
      add :amount, :decimal, precision: 18, scale: 2, null: false, default: 0
      add :project_code, :string
      add :mvag, :string
      add :section, :string

      timestamps(type: :utc_datetime)
    end

    create index(:budget_line_items, [:fiscal_year_id, :ansatz_code])
    create index(:budget_line_items, [:fiscal_year_id])
  end
end
