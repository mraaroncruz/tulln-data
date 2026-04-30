defmodule TullnData.WmsProxy.Cache do
  @moduledoc false

  use GenServer

  @table __MODULE__
  @ttl_seconds 86_400
  @max_entries 1_000

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts, name: __MODULE__)

  def get(key) do
    if :ets.whereis(@table) == :undefined do
      :miss
    else
      case :ets.lookup(@table, key) do
        [{^key, body, content_type, expires_at}] ->
          if System.system_time(:second) < expires_at do
            {:ok, body, content_type}
          else
            :ets.delete(@table, key)
            :miss
          end

        [] ->
          :miss
      end
    end
  end

  def put(key, body, content_type) do
    if :ets.whereis(@table) != :undefined do
      expires_at = System.system_time(:second) + @ttl_seconds
      :ets.insert(@table, {key, body, content_type, expires_at})

      if :ets.info(@table, :size) > @max_entries do
        GenServer.cast(__MODULE__, :evict)
      end
    end

    :ok
  end

  @inflight_key {__MODULE__, :inflight}

  def inflight_counter, do: :persistent_term.get(@inflight_key, nil)

  @impl true
  def init(_opts) do
    :ets.new(@table, [:set, :public, :named_table, read_concurrency: true])
    :persistent_term.put(@inflight_key, :atomics.new(1, signed: true))
    {:ok, %{}}
  end

  @impl true
  def handle_cast(:evict, state) do
    keep = trunc(@max_entries * 0.8)
    drop = :ets.info(@table, :size) - keep

    if drop > 0 do
      @table
      |> :ets.tab2list()
      |> Enum.sort_by(fn {_k, _b, _ct, exp} -> exp end)
      |> Enum.take(drop)
      |> Enum.each(fn {k, _, _, _} -> :ets.delete(@table, k) end)
    end

    {:noreply, state}
  end
end
