defmodule LanternUI.Components.MatrixTable do
  @moduledoc """
  Environment-by-component grid: rows are things (environments), columns are
  components, every cell is one state. Pure server render; no JS.

      <.matrix_table caption="Environments across components" corner="Environment">
        <:col kind="app">web</:col>
        <:col kind="app">worker</:col>
        <:col kind="database">primary</:col>

        <.matrix_row label="main" navigate={~p"/p/1/environments/main"}>
          <:meta>production</:meta>
          <.matrix_cell state="present" label="Ready" navigate={~p"/p/1/apps/9"} />
          <.matrix_cell state="degraded" label="Degraded" navigate={~p"/p/1/apps/10"} />
          <.matrix_cell state="in_rule" navigate={~p"/p/1/environments/main"} />
        </.matrix_row>
        <.matrix_row label="dev/maya" depth={1}>
          <.matrix_cell state="present" label="Ready" />
          <.matrix_cell state="absent" add_label="Add worker to dev/maya" phx-click="add" phx-value-env="maya" />
          <.matrix_cell state="absent" add_label="Add primary to dev/maya" phx-click="add" />
        </.matrix_row>
        <.table_placeholder_row colspan={4} icon="chevron-down" label="3 previews" phx-click="show_previews" />
      </.matrix_table>

  `matrix_table` renders the header (one `th scope="col"` per `:col`) and the
  body wrapper; `matrix_row` is one `tr` whose first cell is a sticky
  `th scope="row"` (indented by `depth`, with an optional link and a `:meta`
  line); `matrix_cell` is one `td`. The caller keeps rows and cells in column
  order. A "+N previews" overflow control is a `table_placeholder_row` in the
  body, so there is no preview column and no second overflow component.

  Cell states: `present`, `degraded`, `failed`, `in_rule` (in the fork rule,
  no instance yet) and `absent`. Each cell shows a dot **and** words (`label`,
  defaulting to the state name), so meaning never rests on colour. Give a cell
  `navigate`/`patch`/`href` to open the thing it names. An `absent` cell with
  `add_label` renders a native "+" button (extra `phx-*` attrs pass through);
  without it, it renders a quiet "Absent". A cell is a link **or** an add
  button, never nested controls.

  Keyboard: links and buttons are native tab stops. The grid is a plain
  `table`, so screen readers announce the row and column header for each cell;
  the first column stays pinned while the wrap scrolls horizontally. Nothing
  animates (so reduced motion needs no override). The caller owns all state,
  ordering, nesting and write events. Use `data_table` for sortable record
  lists; this is for a fixed grid of states.
  """
  use Phoenix.Component

  alias LanternUI.Class
  alias LanternUI.Components.Button
  alias LanternUI.Components.Icon

  @states ~w(present degraded failed in_rule absent)
  @state_words %{
    "present" => "Present",
    "degraded" => "Degraded",
    "failed" => "Failed",
    "in_rule" => "In rule",
    "absent" => "Absent"
  }

  attr(:caption, :string,
    required: true,
    doc: "Screen-reader caption describing the grid and what the cell states mean."
  )

  attr(:corner, :string, default: nil, doc: "Visible header of the pinned first column.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the wrap.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through to the wrap.")

  slot :col, required: true, doc: "One component column header, in cell order." do
    attr(:kind, :string, doc: "Quiet second line, e.g. app or database.")
    attr(:class, :any, doc: "Extra classes on this header cell.")

    attr(:selected, :boolean,
      doc: "Marks the column as the current selection (header + cells via `col_selected`)."
    )

    attr(:select_event, :string, doc: "phx-click event; the header becomes a select button.")

    attr(:select_values, :map,
      doc: "phx-value-* pairs sent with `select_event`, e.g. %{ref: \"app:1\"}."
    )
  end

  slot(:inner_block,
    required: true,
    doc: "matrix_row children (and an optional placeholder row)."
  )

  def matrix_table(assigns) do
    ~H"""
    <div class={Class.merge(["lui-table-wrap lui-matrix", @class])} {@rest}>
      <table class="lui-table">
        <caption class="lui-sr-only">{@caption}</caption>
        <thead class="lui-thead">
          <tr>
            <th class="lui-th lui-matrix-corner" scope="col">{@corner}</th>
            <th
              :for={col <- @col}
              class={Class.merge(["lui-th", col[:class]])}
              scope="col"
              data-selected={col[:selected] || nil}
            >
              <button
                :if={col[:select_event]}
                type="button"
                class="lui-matrix-col lui-matrix-select"
                aria-pressed={to_string(!!col[:selected])}
                phx-click={col[:select_event]}
                {select_attrs(col[:select_values])}
              >
                {render_slot(col)}
              </button>
              <span :if={!col[:select_event]} class="lui-matrix-col">{render_slot(col)}</span>
              <span :if={col[:kind]} class="lui-matrix-kind">{col[:kind]}</span>
            </th>
          </tr>
        </thead>
        <tbody class="lui-tbody">
          {render_slot(@inner_block)}
        </tbody>
      </table>
    </div>
    """
  end

  attr(:label, :string, required: true, doc: "Row name, e.g. the environment.")

  attr(:depth, :integer,
    default: 0,
    doc: "Nesting level; indents the row head (fork parent -> child)."
  )

  attr(:navigate, :string, default: nil, doc: "LiveView navigate target for the row head.")
  attr(:patch, :string, default: nil, doc: "LiveView patch target for the row head.")
  attr(:href, :any, default: nil, doc: "External/full-page href for the row head.")

  attr(:select_event, :string,
    default: nil,
    doc: "phx-click event; the row head becomes a select button (instead of a link)."
  )

  attr(:select_values, :map, default: %{}, doc: "phx-value-* pairs sent with `select_event`.")
  attr(:selected, :boolean, default: false, doc: "Marks the row as the current selection.")

  attr(:trail, :list,
    default: [],
    doc:
      "Tree guides for a nested row: one boolean per ancestor level below the root " <>
        "(`depth - 1` of them); true draws that ancestor's vertical line through this row."
  )

  attr(:last, :boolean, default: false, doc: "Last child of its parent: the elbow closes there.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the row.")
  attr(:rest, :global, doc: "Arbitrary HTML/`phx-*` attributes passed through to the row.")

  slot(:meta, doc: "Quiet line under the name: production, expiry, flags.")
  slot(:inner_block, required: true, doc: "matrix_cell children in column order.")

  def matrix_row(assigns) do
    assigns = assign(assigns, :link?, !!(assigns.navigate || assigns.patch || assigns.href))

    ~H"""
    <tr
      class={Class.merge(["lui-tr", @class])}
      data-depth={@depth}
      data-selected={@selected || nil}
      aria-current={@selected && "true"}
      {@rest}
    >
      <th class="lui-td lui-matrix-head" scope="row" style={"--lui-matrix-depth: #{@depth}"}>
        <span :if={@depth > 0} class="lui-matrix-tree" aria-hidden="true">
          <span :for={on <- @trail} class="lui-matrix-guide" data-on={on || nil}></span>
          <span class="lui-matrix-elbow" data-last={@last || nil}></span>
        </span>
        <button
          :if={@select_event}
          type="button"
          class="lui-matrix-name lui-matrix-select"
          aria-pressed={to_string(@selected)}
          phx-click={@select_event}
          {select_attrs(@select_values)}
        >
          {@label}
        </button>
        <.link
          :if={!@select_event and @link?}
          class="lui-matrix-name"
          navigate={@navigate}
          patch={@patch}
          href={@href}
        >
          {@label}
        </.link>
        <span :if={!@select_event and !@link?} class="lui-matrix-name">{@label}</span>
        <span :if={@meta != []} class="lui-matrix-meta">{render_slot(@meta)}</span>
      </th>
      {render_slot(@inner_block)}
    </tr>
    """
  end

  attr(:state, :string,
    required: true,
    values: @states,
    doc: "present, degraded, failed, in_rule or absent."
  )

  attr(:label, :string, default: nil, doc: "Visible words; defaults to the state name.")

  attr(:add_label, :string,
    default: nil,
    doc: "Accessible name of the add button, e.g. \"Add worker to dev/maya\". Absent cells only."
  )

  attr(:navigate, :string,
    default: nil,
    doc: "LiveView navigate target; the cell reads as a link."
  )

  attr(:patch, :string, default: nil, doc: "LiveView patch target; the cell reads as a link.")
  attr(:href, :any, default: nil, doc: "External/full-page href; the cell reads as a link.")
  attr(:class, :any, default: nil, doc: "Extra classes merged onto the cell.")

  attr(:select_event, :string,
    default: nil,
    doc: "phx-click event; a non-absent cell becomes a select button (instead of a link)."
  )

  attr(:select_values, :map, default: %{}, doc: "phx-value-* pairs sent with `select_event`.")
  attr(:selected, :boolean, default: false, doc: "This cell is the current selection.")
  attr(:col_selected, :boolean, default: false, doc: "This cell sits in the selected column.")
  attr(:rest, :global, doc: "`phx-*` attrs passed to the add button (absent + add_label).")

  def matrix_cell(assigns) do
    state = to_string(assigns.state)
    word = Map.fetch!(@state_words, state)

    assigns =
      assigns
      |> assign(:state, state)
      |> assign(:text, assigns.label || word)
      |> assign(:link?, !!(assigns.navigate || assigns.patch || assigns.href))

    ~H"""
    <td
      class={Class.merge(["lui-td lui-matrix-cell", @class])}
      data-state={@state}
      data-selected={@selected || nil}
      data-col-selected={@col_selected || nil}
    >
      <Button.button
        :if={@state == "absent" and @add_label}
        variant="ghost"
        size="icon-xs"
        label={@add_label}
        {@rest}
      >
        <Icon.icon name="plus" />
      </Button.button>
      <%= if !(@state == "absent" and @add_label) do %>
        <button
          :if={@select_event}
          type="button"
          class="lui-matrix-state lui-matrix-select"
          aria-pressed={to_string(@selected)}
          phx-click={@select_event}
          {select_attrs(@select_values)}
        >
          <.state_body state={@state} text={@text} />
        </button>
        <.link
          :if={!@select_event and @link?}
          class="lui-matrix-state"
          navigate={@navigate}
          patch={@patch}
          href={@href}
        >
          <.state_body state={@state} text={@text} />
        </.link>
        <span :if={!@select_event and !@link?} class="lui-matrix-state">
          <.state_body state={@state} text={@text} />
        </span>
      <% end %>
    </td>
    """
  end

  attr(:state, :string, required: true)
  attr(:text, :string, required: true)

  defp state_body(assigns) do
    ~H"""
    <span class="lui-matrix-dot" aria-hidden="true"></span>{@text}<span
      :if={@text != state_word(@state)}
      class="lui-sr-only"
    >, {String.downcase(state_word(@state))}</span>
    """
  end

  defp select_attrs(nil), do: []
  defp select_attrs(values), do: Map.new(values, fn {k, v} -> {"phx-value-#{k}", v} end)

  defp state_word(state), do: Map.fetch!(@state_words, state)
end
