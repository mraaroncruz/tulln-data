defmodule TullnData.Hora.GmlHandler do
  @moduledoc false

  defstruct [
    :bezirk_prefix,
    :return_period,
    features: [],
    current_feature: nil,
    path: [],
    chars: ""
  ]

  def initial_state(bezirk_prefix, return_period) do
    %__MODULE__{bezirk_prefix: bezirk_prefix, return_period: return_period}
  end

  def features(%__MODULE__{features: features}), do: Enum.reverse(features)

  def handle_event({:startElement, _uri, local_name, _qname, _attrs}, _loc, state) do
    name = to_string(local_name)
    state = %{state | path: [name | state.path], chars: ""}

    case name do
      "HazardArea" ->
        %{state | current_feature: %{source_id: nil, geom: nil, source_updated_at: nil}}

      _ ->
        state
    end
  end

  def handle_event({:endElement, _uri, local_name, _qname}, _loc, state) do
    name = to_string(local_name)
    chars = String.trim(state.chars)

    state = apply_element(state, name, chars)
    %{state | path: tl(state.path), chars: ""}
  end

  def handle_event({:characters, chars}, _loc, state) do
    %{state | chars: state.chars <> to_string(chars)}
  end

  def handle_event(_event, _loc, state), do: state

  defp apply_element(state, "localId", value) when state.current_feature != nil do
    put_in(state.current_feature.source_id, value)
  end

  defp apply_element(state, "beginLifeSpanVersion", value) when state.current_feature != nil do
    case DateTime.from_iso8601(value) do
      {:ok, dt, _offset} ->
        put_in(state.current_feature.source_updated_at, DateTime.truncate(dt, :second))

      _ ->
        state
    end
  end

  defp apply_element(state, "posList", value) when state.current_feature != nil do
    case parse_pos_list(value) do
      {:ok, ring} -> put_in(state.current_feature.geom, ring)
      _ -> state
    end
  end

  defp apply_element(state, "HazardArea", _value) do
    feature = state.current_feature

    if feature && feature.source_id && feature.geom &&
         String.starts_with?(feature.source_id, state.bezirk_prefix) do
      geom = %Geo.Polygon{
        coordinates: [feature.geom],
        srid: 4326
      }

      completed = %{
        source_id: feature.source_id,
        geom: geom,
        source_updated_at: feature.source_updated_at
      }

      %{state | features: [completed | state.features], current_feature: nil}
    else
      %{state | current_feature: nil}
    end
  end

  defp apply_element(state, _name, _value), do: state

  defp parse_pos_list(text) do
    numbers =
      text
      |> String.split()
      |> Enum.map(&parse_float/1)

    if Enum.any?(numbers, &is_nil/1) || rem(length(numbers), 2) != 0 do
      :error
    else
      coords =
        numbers
        |> Enum.chunk_every(2)
        |> Enum.map(fn [lat, lon] -> {lon, lat} end)

      {:ok, coords}
    end
  end

  defp parse_float(str) do
    case Float.parse(str) do
      {f, ""} -> f
      _ -> nil
    end
  end
end
