defmodule TullnData.PromEx.BudgetPlugin do
  @moduledoc """
  PromEx plugin for budget CSV ingestion metrics, sourced from the
  `[:tulln_data, :budget, :download]` telemetry event emitted by
  `TullnData.Budget.Client`.
  """

  use PromEx.Plugin

  @download_event [:tulln_data, :budget, :download]

  @impl true
  def event_metrics(_opts) do
    Event.build(
      :tulln_data_budget_event_metrics,
      [
        counter(
          [:tulln_data, :budget, :download, :total],
          event_name: @download_event,
          description: "Total budget CSV download attempts, by source and result.",
          tags: [:source, :result]
        ),
        distribution(
          [:tulln_data, :budget, :download, :duration, :milliseconds],
          event_name: @download_event,
          measurement: :duration,
          description: "Budget CSV download duration in milliseconds.",
          tags: [:source, :result],
          unit: {:native, :millisecond},
          reporter_options: [
            buckets: [100, 250, 500, 1_000, 2_500, 5_000, 10_000, 30_000]
          ]
        )
      ]
    )
  end
end
