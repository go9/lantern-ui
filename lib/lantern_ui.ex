defmodule LanternUI do
  @moduledoc """
  LanternUI — a dev-tool-native, open-source component system for Phoenix LiveView.

  Server-rendered HEEx/SVG components with thin JS hooks and no React or JS UI
  libraries. Built for embeddable developer tools (lantern, livecode, s3) first,
  and as a lightweight, drop-in replacement for Fluxon over time.

  ## Usage

  Import the whole component set the way you would Fluxon:

      use LanternUI

  or a subset:

      use LanternUI, only: [:charts]
      use LanternUI, except: [:charts]

  Then call components directly in HEEx (`<.area_chart .../>`, and — as they land —
  `<.button>`, `<.date_time_picker>`, …). The public API mirrors Fluxon's so a
  consumer can migrate by swapping `use Fluxon` for `use LanternUI`.

  ## Theming

  Components read every value from `--lantern-*` CSS variables, each chained to a
  host (Fluxon) token then a hard fallback, so they match a host design system
  automatically and still render standalone via the optional theme + tokens in
  `priv/static/lantern_ui.css` (light/dark + a `data-lantern-density="compact"`
  dev-tool mode). See the README for installation and JS hook setup.
  """

  # Registry of importable component groups → module. Grows as components land
  # (Phase 1: :button, :icon, :calendar, :date_picker, …). Keys are what
  # `use LanternUI, only:/except:` filters on.
  @components %{
    charts: LanternUI.Charts,
    button: LanternUI.Components.Button,
    icon: LanternUI.Components.Icon,
    form: LanternUI.Components.Form,
    calendar: LanternUI.Components.Calendar,
    datetime_field: LanternUI.Components.DatetimeField,
    date_picker: LanternUI.Components.DatePicker,
    checkbox: LanternUI.Components.Checkbox,
    modal: LanternUI.Components.Modal,
    dropdown: LanternUI.Components.Dropdown,
    breadcrumb: LanternUI.Components.Breadcrumb,
    empty_state: LanternUI.Components.EmptyState,
    layout: LanternUI.Components.Layout,
    badge: LanternUI.Components.Badge,
    table: LanternUI.Components.Table,
    tabs: LanternUI.Components.Tabs,
    select: LanternUI.Components.Select,
    pagination: LanternUI.Components.Pagination,
    data_table: LanternUI.Components.DataTable,
    switch: LanternUI.Components.Switch,
    radio: LanternUI.Components.Radio,
    textarea: LanternUI.Components.Textarea,
    alert: LanternUI.Components.Alert,
    separator: LanternUI.Components.Separator,
    tooltip: LanternUI.Components.Tooltip,
    toast: LanternUI.Components.Toast,
    theme: LanternUI.Components.Theme,
    sheet: LanternUI.Components.Sheet
  }

  @doc false
  def __components__, do: @components

  @doc """
  Open a `LanternUI.Components.Modal` by id — client command or server push.

      <.button phx-click={LanternUI.open_dialog("confirm")}>Open</.button>
      {:noreply, LanternUI.open_dialog(socket, "confirm")}

  Mirrors `Fluxon.open_dialog/1,2`.
  """
  def open_dialog(id) when is_binary(id), do: open_dialog(%Phoenix.LiveView.JS{}, id)

  def open_dialog(%Phoenix.LiveView.Socket{} = socket, id),
    do: Phoenix.LiveView.push_event(socket, "lantern:dialog:open", %{id: id})

  def open_dialog(%Phoenix.LiveView.JS{} = js, id),
    do: Phoenix.LiveView.JS.dispatch(js, "lantern:dialog:open", to: "##{id}")

  @doc """
  Close a `LanternUI.Components.Modal` by id — client command or server push.
  Mirrors `Fluxon.close_dialog/1,2`.
  """
  def close_dialog(id) when is_binary(id), do: close_dialog(%Phoenix.LiveView.JS{}, id)

  def close_dialog(%Phoenix.LiveView.Socket{} = socket, id),
    do: Phoenix.LiveView.push_event(socket, "lantern:dialog:close", %{id: id})

  def close_dialog(%Phoenix.LiveView.JS{} = js, id),
    do: Phoenix.LiveView.JS.dispatch(js, "lantern:dialog:close", to: "##{id}")

  @doc """
  Push a toast notification to a `LanternUI.Components.Toast.toast_group/1`.
  """
  def send_toast(%Phoenix.LiveView.Socket{} = socket, kind, message, opts \\ []) do
    Phoenix.LiveView.push_event(socket, "lantern:toast", %{
      kind: to_string(kind),
      message: message,
      title: opts[:title],
      duration: opts[:duration] || 4000
    })
  end

  @doc "Apply persisted runtime theme overrides (see LanternUI.Components.Theme)."
  def set_theme(%Phoenix.LiveView.Socket{} = socket, %{} = config) do
    Phoenix.LiveView.push_event(socket, "lantern:set-theme", config)
  end

  @doc "Clear persisted runtime theme overrides."
  def reset_theme(%Phoenix.LiveView.Socket{} = socket) do
    Phoenix.LiveView.push_event(socket, "lantern:set-theme", %{reset: true})
  end

  defmacro __using__(opts) do
    only = Keyword.get(opts, :only, [])
    except = Keyword.get(opts, :except, [])

    for {_key, module} <- LanternUI.__filter_components__(only, except) do
      quote do: import(unquote(module))
    end
  end

  @doc false
  def __filter_components__(only, except) do
    @components
    |> Enum.filter(fn {key, _module} ->
      cond do
        only != [] -> key in only
        except != [] -> key not in except
        true -> true
      end
    end)
  end
end
