defmodule LanternUI.Components.DiffViewer do
  @moduledoc """
  Line diff of two texts, unified or side by side. Pure server render; no JS.

      <.diff_viewer
        id="contract-diff"
        old={@server_contract}
        new={@draft_contract}
        old_label="Server"
        new_label="Draft"
      />

  The component diffs `old` against `new` by line, so the caller passes text,
  not hunks. Unchanged runs longer than `context` lines on each side collapse
  to one "N unchanged lines" row. Equal texts render a single "No differences"
  line. Lines are plain text (escaped, whitespace preserved); there is no
  syntax highlighting or inline word diff.

  Added and removed lines carry a visible `+` / `−` sign and screen-reader text
  ("Added" / "Removed"), so colour is never the only signal. The table is a
  focusable, named scroll region so long lines can be scrolled by keyboard. It
  has no interaction and no animation. Mask secrets before rendering: the
  component shows exactly what it is given (for a `.env` import, diff key names
  only).

  Use it for contract, AGENTS.md and revision review. Adopt/restore/approve
  buttons belong to the caller, next to the viewer.
  """
  use Phoenix.Component

  alias LanternUI.Class

  attr(:old, :string, required: true, doc: "Previous text.")
  attr(:new, :string, required: true, doc: "Proposed text.")
  attr(:old_label, :string, default: "Before", doc: "Name of the old side, used in labels.")
  attr(:new_label, :string, default: "After", doc: "Name of the new side, used in labels.")

  attr(:mode, :atom,
    default: :unified,
    values: [:unified, :split],
    doc:
      "`:split` shows old and new side by side; below the `sm` breakpoint it stays readable by scrolling."
  )

  attr(:context, :integer,
    default: 3,
    doc: "Unchanged lines kept around each change; longer runs collapse."
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root.")
  attr(:rest, :global, doc: "HTML/`phx-*` attrs, e.g. `id`.")

  def diff_viewer(assigns) do
    rows = rows(assigns.old, assigns.new, max(assigns.context, 0))

    assigns =
      assigns
      |> assign(:rows, rows)
      |> assign(:changed?, Enum.any?(rows, &(&1.kind in [:add, :del])))
      |> assign(:summary, summary(rows, assigns.old_label, assigns.new_label))

    ~H"""
    <div
      class={Class.merge(["lui-diff", @class])}
      data-mode={@mode}
      role="region"
      aria-label={@summary}
      tabindex="0"
      {@rest}
    >
      <p :if={!@changed?} class="lui-diff-empty">No differences</p>
      <table :if={@changed?} class="lui-diff-table">
        <caption class="lui-sr-only">{@summary}</caption>
        <thead class="lui-sr-only">
          <tr :if={@mode == :unified}>
            <th scope="col">{@old_label} line</th>
            <th scope="col">{@new_label} line</th>
            <th scope="col">Change</th>
            <th scope="col">Text</th>
          </tr>
          <tr :if={@mode == :split}>
            <th scope="col">{@old_label} line</th>
            <th scope="col">{@old_label}</th>
            <th scope="col">{@new_label} line</th>
            <th scope="col">{@new_label}</th>
          </tr>
        </thead>
        <tbody :if={@mode == :unified}>
          <%= for row <- @rows do %>
            <tr :if={row.kind == :gap} class="lui-diff-gap">
              <td colspan="4">{unchanged(row.count)}</td>
            </tr>
            <tr :if={row.kind != :gap} class="lui-diff-row" data-kind={row.kind}>
              <td class="lui-diff-no">{row[:old_no]}</td>
              <td class="lui-diff-no">{row[:new_no]}</td>
              <td class="lui-diff-sign">
                <span aria-hidden="true">{sign(row.kind)}</span><span class="lui-sr-only">{word(
                  row.kind
                )}</span>
              </td>
              <td class="lui-diff-text"><span class="lui-diff-line">{row.text}</span></td>
            </tr>
          <% end %>
        </tbody>
        <tbody :if={@mode == :split}>
          <%= for row <- split(@rows) do %>
            <tr :if={row.kind == :gap} class="lui-diff-gap">
              <td colspan="4">{unchanged(row.count)}</td>
            </tr>
            <tr :if={row.kind != :gap} class="lui-diff-row">
              <td class="lui-diff-no">{row.left[:old_no]}</td>
              <td class="lui-diff-text" data-kind={row.left && row.left.kind}>
                <.diff_cell cell={row.left} />
              </td>
              <td class="lui-diff-no">{row.right[:new_no]}</td>
              <td class="lui-diff-text" data-kind={row.right && row.right.kind}>
                <.diff_cell cell={row.right} />
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
    """
  end

  defp diff_cell(%{cell: nil} = assigns), do: ~H""

  defp diff_cell(assigns) do
    ~H"""
    <span :if={@cell.kind != :eq} aria-hidden="true">{sign(@cell.kind)}</span><span
      :if={@cell.kind != :eq}
      class="lui-sr-only"
    >{word(@cell.kind)}: </span><span class="lui-diff-line">{@cell.text}</span>
    """
  end

  defp sign(:add), do: "+"
  defp sign(:del), do: "−"
  defp sign(_), do: ""

  defp word(:add), do: "Added"
  defp word(:del), do: "Removed"
  defp word(_), do: ""

  defp unchanged(1), do: "1 unchanged line"
  defp unchanged(n), do: "#{n} unchanged lines"

  defp summary(rows, old_label, new_label) do
    added = Enum.count(rows, &(&1.kind == :add))
    removed = Enum.count(rows, &(&1.kind == :del))

    "Changes from #{old_label} to #{new_label}: #{added} #{plural(added, "line")} added, " <>
      "#{removed} #{plural(removed, "line")} removed"
  end

  defp plural(1, word), do: word
  defp plural(_, word), do: word <> "s"

  # Unified rows with line numbers; long equal runs collapse to a gap row.
  defp rows(old, new, context) do
    {_, _, rows} =
      old
      |> lines()
      |> List.myers_difference(lines(new))
      |> Enum.reduce({1, 1, []}, fn
        {:eq, ls}, {o, n, acc} ->
          eq =
            ls
            |> Enum.with_index()
            |> Enum.map(fn {t, i} -> %{kind: :eq, old_no: o + i, new_no: n + i, text: t} end)

          {o + length(ls), n + length(ls), [{:eq, eq} | acc]}

        {:del, ls}, {o, n, acc} ->
          del =
            ls
            |> Enum.with_index()
            |> Enum.map(fn {t, i} -> %{kind: :del, old_no: o + i, text: t} end)

          {o + length(ls), n, [{:chg, del} | acc]}

        {:ins, ls}, {o, n, acc} ->
          ins =
            ls
            |> Enum.with_index()
            |> Enum.map(fn {t, i} -> %{kind: :add, new_no: n + i, text: t} end)

          {o, n + length(ls), [{:chg, ins} | acc]}
      end)

    runs = Enum.reverse(rows)
    last = length(runs) - 1

    runs
    |> Enum.with_index()
    |> Enum.flat_map(fn
      {{:chg, ls}, _} -> ls
      {{:eq, ls}, i} -> collapse(ls, context, i == 0, i == last)
    end)
  end

  defp lines(""), do: []
  defp lines(text), do: String.split(text, ~r/\r?\n/)

  defp collapse(ls, context, first?, last?) do
    head = if first?, do: 0, else: context
    tail = if last?, do: 0, else: context
    count = length(ls)

    if count > head + tail + 1 do
      Enum.take(ls, head) ++
        [%{kind: :gap, count: count - head - tail}] ++ Enum.take(ls, -tail)
    else
      ls
    end
  end

  # Pair each run of removed lines with the added lines that follow it.
  defp split(rows), do: do_split(rows, [])

  defp do_split([], acc), do: Enum.reverse(acc)

  defp do_split([%{kind: :gap} = gap | rest], acc), do: do_split(rest, [gap | acc])

  defp do_split([%{kind: :eq} = r | rest], acc),
    do: do_split(rest, [%{kind: :eq, left: r, right: r} | acc])

  defp do_split(rows, acc) do
    {dels, rest} = Enum.split_while(rows, &(&1.kind == :del))
    {adds, rest} = Enum.split_while(rest, &(&1.kind == :add))
    n = max(length(dels), length(adds))

    pairs =
      for i <- 0..(n - 1)//1 do
        %{kind: :chg, left: Enum.at(dels, i), right: Enum.at(adds, i)}
      end

    do_split(rest, Enum.reverse(pairs) ++ acc)
  end
end
