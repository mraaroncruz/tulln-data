defmodule TullnData.Budgets.Treemap do
  @moduledoc """
  Pure-Elixir squarified-treemap layout (Bruls, Huijsen & van Wijk, 2000).

  Takes a list of items each carrying a `:amount` field and a viewport
  `{width, height}` in arbitrary units, and returns a list of `%{x, y, w, h}`
  rectangles in viewport-space — one per input item, in the same order.
  Items with non-positive amounts are dropped.

  Suitable for rendering as SVG `<rect>` elements.
  """

  @doc """
  Layout `items` (each with `:amount`) inside the rectangle `(0, 0, w, h)`.

  Returns a list of `%{item, x, y, w, h}` maps. The squarified algorithm
  produces tiles whose aspect ratios are as close to 1:1 as possible.
  """
  def layout(items, w, h) when is_list(items) and is_number(w) and is_number(h) do
    items
    |> Enum.map(fn item -> Map.update!(item, :amount, &amount_to_float/1) end)
    |> Enum.filter(&(&1.amount > 0))
    |> Enum.sort_by(& &1.amount, :desc)
    |> case do
      [] -> []
      filtered -> squarify(filtered, [], 0.0, 0.0, w * 1.0, h * 1.0, total_value(filtered), [])
    end
    |> Enum.reverse()
  end

  defp amount_to_float(%Decimal{} = d), do: Decimal.to_float(d)
  defp amount_to_float(n) when is_number(n), do: n * 1.0

  defp total_value(items), do: Enum.reduce(items, 0.0, &(&1.amount + &2))

  # Recursive squarify. Maintains a current row of accepted items and the
  # remaining sub-rectangle to fill.
  defp squarify([], row, x, y, w, h, _v, acc) do
    layout_row(row, x, y, w, h, acc)
  end

  defp squarify([item | rest] = all, row, x, y, w, h, v, acc) do
    shorter = min(w, h)
    new_row = [item | row]

    if row == [] do
      squarify(rest, new_row, x, y, w, h, v, acc)
    else
      current_worst = worst_aspect(row, shorter, v, w, h)
      new_worst = worst_aspect(new_row, shorter, v, w, h)

      if new_worst <= current_worst do
        squarify(rest, new_row, x, y, w, h, v, acc)
      else
        # Adding the next item would make things worse. Lay out the current
        # row, then recurse on the remaining items in the leftover rectangle.
        {acc2, new_x, new_y, new_w, new_h} = consume_row(row, x, y, w, h, v, acc)
        new_v = v - row_value(row)
        squarify(all, [], new_x, new_y, new_w, new_h, new_v, acc2)
      end
    end
  end

  # Worst aspect ratio in a row given the shorter side of the remaining
  # rectangle and the total value still to be plotted.
  defp worst_aspect(row, shorter, v, w, h) do
    row_total = row_value(row)
    # Area this row will consume = row_total / v * (w * h)
    # Row depth (perpendicular to `shorter`) = area / shorter
    area = row_total / v * w * h
    depth = area / shorter

    Enum.reduce(row, 0.0, fn item, worst ->
      item_share = item.amount / row_total
      item_length = shorter * item_share
      r = max(depth / item_length, item_length / depth)
      max(r, worst)
    end)
  end

  defp row_value(row), do: Enum.reduce(row, 0.0, &(&1.amount + &2))

  # Lay out an already-finalized row and update the remaining rectangle.
  defp consume_row(row, x, y, w, h, v, acc) do
    row_total = row_value(row)
    area = row_total / v * w * h
    # row laid along the longer side; thickness on the shorter side
    if w <= h do
      thickness = area / w
      acc = layout_row(Enum.reverse(row), x, y, w, thickness, acc)
      {acc, x, y + thickness, w, h - thickness}
    else
      thickness = area / h
      acc = layout_row_vertical(Enum.reverse(row), x, y, thickness, h, acc)
      {acc, x + thickness, y, w - thickness, h}
    end
  end

  # Laid horizontally — each tile takes width proportional to its value share.
  defp layout_row(row, x, y, w, h, acc) do
    total = row_value(row)

    {_, acc} =
      Enum.reduce(row, {x, acc}, fn item, {cur_x, results} ->
        tile_w = w * (item.amount / total)
        rect = %{item: drop_amount(item), x: cur_x, y: y, w: tile_w, h: h}
        {cur_x + tile_w, [rect | results]}
      end)

    acc
  end

  # Laid vertically — each tile takes height proportional to its value share.
  defp layout_row_vertical(row, x, y, w, h, acc) do
    total = row_value(row)

    {_, acc} =
      Enum.reduce(row, {y, acc}, fn item, {cur_y, results} ->
        tile_h = h * (item.amount / total)
        rect = %{item: drop_amount(item), x: x, y: cur_y, w: w, h: tile_h}
        {cur_y + tile_h, [rect | results]}
      end)

    acc
  end

  # The amount stays in the item map for downstream rendering (labels, tooltips).
  defp drop_amount(item), do: item
end
