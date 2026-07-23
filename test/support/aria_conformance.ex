defmodule LanternUI.ARIAConformance do
  @moduledoc """
  Structural ARIA gate for server-rendered component HTML.

  Two mechanical checks, both of which a human reviewer reliably misses:

    1. **Idref resolution** — every `aria-controls` / `aria-labelledby` /
       `aria-describedby` / `aria-activedescendant` token must point at an
       element that exists **in the same render**. This catches the dangling
       reference that conditional children produce: a panel rendered
       `:if={@active}` makes `aria-controls` on inactive triggers point at
       nothing.

    2. **Role companions** — every `role` present must carry the attributes its
       WAI-ARIA APG pattern requires (a `tab` without `aria-selected` is not a
       tab; a `switch` without `aria-checked` has no state).

  ## Server vs hook ownership (why this is not a naive checker)

  LanternUI splits ARIA state between the server render and the JS hooks.
  `aria-expanded="false"` is a **static literal** in the HEEx that the hook
  flips at runtime (`setAttribute("aria-expanded", ...)`). Asserting on the
  server render alone would flag correct code.

  So a component declares which attributes its hook owns, and those are exempt
  from the server-side assertion:

      audit(html, hook_owned: ["aria-expanded", "aria-activedescendant"])

  Hook-owned attributes are *declared*, not ignored — the declaration is the
  contract. Runtime behavior for those belongs in a JS/e2e test.

  ## Usage

      test "tabs" do
        html = render(&Tabs.tabs/1, %{...})
        assert ARIAConformance.audit(html) == []
      end

  `audit/2` returns a list of violation structs; `[]` means conformant.
  """

  @idref_attrs ~w(aria-controls aria-labelledby aria-describedby aria-activedescendant)

  # WAI-ARIA APG: role => attributes that role is meaningless without.
  @role_companions %{
    "tab" => ~w(aria-selected aria-controls),
    "tabpanel" => ~w(aria-labelledby),
    "combobox" => ~w(aria-controls aria-expanded),
    "switch" => ~w(aria-checked),
    "option" => ~w(aria-selected),
    "spinbutton" => ~w(aria-valuenow),
    "columnheader" => []
  }

  # Roles that need an accessible name from *either* source.
  @needs_accessible_name ~w(dialog alertdialog menu listbox tablist tooltip)

  defmodule Violation do
    @moduledoc false
    defstruct [:kind, :role, :attr, :idref, :element, :detail]

    defimpl String.Chars do
      def to_string(%{kind: :dangling_idref} = v),
        do: "#{v.attr}=\"#{v.idref}\" on <#{v.element}> points at no element in this render"

      def to_string(%{kind: :missing_companion} = v),
        do: "role=\"#{v.role}\" on <#{v.element}> is missing #{v.attr}"

      def to_string(%{kind: :missing_accessible_name} = v),
        do:
          "role=\"#{v.role}\" on <#{v.element}> has no accessible name (aria-label or aria-labelledby)"
    end
  end

  @doc """
  Audit rendered HTML. Returns `[]` when conformant.

  ## Options

    * `:hook_owned` — attribute names the JS hook sets at runtime. Exempt from
      the server-render assertion. Declaring them IS the contract.
  """
  def audit(html, opts \\ []) when is_binary(html) do
    hook_owned = Keyword.get(opts, :hook_owned, [])
    doc = Floki.parse_fragment!(html)
    ids = collect_ids(doc)

    dangling_idrefs(doc, ids, hook_owned) ++
      missing_companions(doc, hook_owned) ++
      missing_accessible_names(doc, hook_owned)
  end

  @doc "Human-readable report for a failing audit."
  def report(violations) do
    violations |> Enum.map(&"  - #{&1}") |> Enum.join("\n")
  end

  defp collect_ids(doc) do
    doc
    |> Floki.find("[id]")
    |> Enum.map(&Floki.attribute(&1, "id"))
    |> List.flatten()
    |> MapSet.new()
  end

  defp dangling_idrefs(doc, ids, hook_owned) do
    for attr <- @idref_attrs,
        attr not in hook_owned,
        el <- Floki.find(doc, "[#{attr}]"),
        raw <- Floki.attribute(el, attr),
        # idref lists are space-separated; empty/nil means "not rendered", not a violation
        raw not in ["", nil],
        idref <- String.split(raw, ~r/\s+/, trim: true),
        idref not in ids do
      %Violation{kind: :dangling_idref, attr: attr, idref: idref, element: tag(el)}
    end
  end

  defp missing_companions(doc, hook_owned) do
    for {role, required} <- @role_companions,
        el <- Floki.find(doc, ~s([role="#{role}"])),
        attr <- required,
        attr not in hook_owned,
        Floki.attribute(el, attr) == [] do
      %Violation{kind: :missing_companion, role: role, attr: attr, element: tag(el)}
    end
  end

  defp missing_accessible_names(doc, hook_owned) do
    for role <- @needs_accessible_name,
        "aria-label" not in hook_owned,
        el <- Floki.find(doc, ~s([role="#{role}"])),
        Floki.attribute(el, "aria-label") == [],
        Floki.attribute(el, "aria-labelledby") == [] do
      %Violation{kind: :missing_accessible_name, role: role, element: tag(el)}
    end
  end

  defp tag({name, _attrs, _children}), do: name
  defp tag(_), do: "?"
end
