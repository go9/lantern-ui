defmodule LanternUI.Llms do
  @moduledoc """
  Generates `llms.txt` (compact) and `llms-full.txt` (complete reference) from
  the component registry, docs, and recipes.

  Both files are checked in at the package root, shipped in the Hex package,
  and linked from the README. Regenerate with `mix lantern.llms`; CI fails
  when the checked-in files are stale (`mix lantern.llms --check`).

  The catalog and attribute tables come from `LanternUI.__components__/0` plus
  `Code.fetch_docs/1`, so they cannot rot when components change. The HEEx
  blocks are extracted from `docs/recipes.md` and `README.md` — the same
  sources the `lantern-recipes` skill and the recipe tests use.
  """

  @doc """
  Generate `%{short: binary, full: binary}` from the registry under `root`.
  """
  def generate(root \\ File.cwd!()) do
    modules = catalog(root)
    recipes = recipes(root)
    version = version()

    short = short_file(version, modules, recipes)
    full = full_file(version, modules, recipes)

    %{short: short, full: full}
  end

  @doc """
  Write `llms.txt` and `llms-full.txt` into `root`. Returns the paths.
  """
  def write!(root \\ File.cwd!()) do
    %{short: short, full: full} = generate(root)

    short_path = Path.join(root, "llms.txt")
    full_path = Path.join(root, "llms-full.txt")

    File.write!(short_path, short)
    File.write!(full_path, full)

    [short_path, full_path]
  end

  @doc """
  Check the files under `root` are fresh. Returns `:ok` or `{:stale, paths}`.
  """
  def check(root \\ File.cwd!()) do
    %{short: short, full: full} = generate(root)

    stale =
      [{"llms.txt", short}, {"llms-full.txt", full}]
      |> Enum.reject(fn {name, expected} ->
        case File.read(Path.join(root, name)) do
          {:ok, ^expected} -> true
          _ -> false
        end
      end)
      |> Enum.map(&elem(&1, 0))

    case stale do
      [] -> :ok
      paths -> {:stale, paths}
    end
  end

  @doc false
  # `[%{module: mod, summary: binary, components: [%{name:, doc:, attrs:, slots:}]}]`,
  # modules and components sorted. Only components with public docs.
  def catalog(_root \\ File.cwd!()) do
    LanternUI.__components__()
    |> Enum.map(fn {_key, mod} -> mod end)
    |> Enum.uniq()
    |> Enum.sort_by(&inspect/1)
    |> Enum.map(&module_entry/1)
    |> Enum.reject(&(&1.components == []))
  end

  defp module_entry(mod) do
    specs =
      try do
        mod.__components__()
      rescue
        _ -> %{}
      end

    docs = fetch_docs(mod)
    module_summary = first_sentence(confirmed_moduledoc(mod))

    %{
      module: mod,
      summary: module_summary,
      components:
        specs
        |> Enum.map(fn {name, spec} -> {name, spec, Map.get(docs, {name, 1})} end)
        |> Enum.reject(fn {_name, _spec, doc} -> is_nil(doc) end)
        |> Enum.sort_by(fn {name, _, _} -> Atom.to_string(name) end)
        |> Enum.map(fn {name, spec, doc} ->
          prose = first_sentence(doc)

          %{
            name: Atom.to_string(name),
            doc: if(prose == "", do: module_summary, else: prose),
            attrs: Enum.map(spec.attrs, &attr_entry/1),
            slots: Enum.map(spec.slots, &slot_entry/1)
          }
        end)
    }
  end

  defp fetch_docs(mod) do
    case Code.fetch_docs(mod) do
      {:docs_v1, _, _, _, _, _, docs} ->
        for {{:function, name, arity}, _, _, doc, _} <- docs,
            text = doc_text(doc),
            not is_nil(text),
            into: %{} do
          {{name, arity}, text}
        end

      _ ->
        %{}
    end
  end

  defp confirmed_moduledoc(mod) do
    case Code.fetch_docs(mod) do
      {:docs_v1, _, _, _, %{"en" => text}, _, _} -> text
      _ -> ""
    end
  end

  defp doc_text(:none), do: nil
  defp doc_text(:hidden), do: nil
  defp doc_text(%{"en" => text}), do: text
  defp doc_text(text) when is_binary(text), do: text
  defp doc_text(_), do: nil

  defp attr_entry(%{name: name} = attr) do
    %{
      name: Atom.to_string(name),
      type: inspect(Map.get(attr, :type, :any)),
      required: Map.get(attr, :required, false),
      values: attr_values(attr),
      default: attr_default(attr),
      doc: first_sentence(Map.get(attr, :doc) || "")
    }
  end

  defp slot_entry(%{name: name} = slot) do
    %{
      name: Atom.to_string(name),
      required: Map.get(slot, :required, false),
      doc: first_sentence(Map.get(slot, :doc) || ""),
      attrs: slot |> Map.get(:attrs, []) |> Enum.map(&attr_entry/1)
    }
  end

  defp attr_values(attr) do
    case Keyword.get(Map.get(attr, :opts, []) || [], :values) do
      nil -> nil
      values -> Enum.map_join(values, ", ", &to_string/1)
    end
  end

  defp attr_default(attr) do
    case Keyword.get(Map.get(attr, :opts, []) || [], :default) do
      nil -> nil
      default -> inspect(default)
    end
  end

  defp first_sentence(""), do: ""

  # First prose line: skip markdown structure (headings, lists, fences, code,
  # tables) so components whose doc is only the generated attribute list fall
  # back to their module summary at the call site.
  defp first_sentence(text) do
    paragraph =
      text
      |> String.split(~r/\n\s*\n/)
      |> List.first("")
      |> String.split("\n")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == "" or Regex.match?(~r/^(#|\*|-|\||<|>|:\w|\d+\.|```)/, &1)))
      |> Enum.join(" ")

    paragraph
    |> String.split(~r/(?<=[.!?])\s+/, parts: 2)
    |> List.first("")
    |> String.trim()
  end

  @doc false
  # `[%{source:, heading:, code:}]` for every fenced heex block in theats
  # recipes and README, in file order.
  def recipes(root \\ File.cwd!()) do
    ["docs/recipes.md", "README.md"]
    |> Enum.flat_map(fn rel ->
      path = Path.join(root, rel)

      case File.read(path) do
        {:ok, source} -> extract_blocks(source, rel)
        {:error, _} -> []
      end
    end)
  end

  defp extract_blocks(source, rel) do
    lines = String.split(source, "\n")

    {blocks, current, heading} =
      Enum.reduce(lines, {[], nil, nil}, fn line, {blocks, current, heading} ->
        cond do
          match = Regex.run(~r/^##\s+(.+)$/, line) ->
            {blocks, current, List.last(match)}

          String.trim(line) == "```heex" ->
            {blocks, [], heading}

          String.trim(line) == "```" and not is_nil(current) ->
            block = %{source: rel, heading: heading, code: Enum.join(current, "\n")}
            {[block | blocks], nil, heading}

          not is_nil(current) ->
            {blocks, current ++ [line], heading}

          true ->
            {blocks, current, heading}
        end
      end)

    _ = current
    _ = heading
    Enum.reverse(blocks)
  end

  defp version do
    :lantern_ui |> Application.spec(:vsn) |> to_string()
  rescue
    _ -> "dev"
  end

  # ---------------------------------------------------------------------------
  # Rendering
  # ---------------------------------------------------------------------------

  defp short_file(version, modules, recipes) do
    """
    # LanternUI #{version} — llms.txt

    > Native Phoenix LiveView UI components. Server-rendered HEEx/SVG, themed
    > via CSS variables. No React, no JS UI libraries.

    #{rules_section()}

    ## Component catalog

    One line per component: name, then when to use it. Deprecated entries name
    their replacement. Full attribute tables are in llms-full.txt.

    #{catalog_compact(modules)}

    ## Copy-paste recipes

    From docs/recipes.md and README.md (same sources the recipe tests render).
    Copy these blocks instead of inventing markup.

    #{recipes_section(recipes)}

    ## Go deeper

    - `llms-full.txt` — every component with attribute/slot tables, values,
      deprecations, and tokens.
    - `mix lantern.lint` — fails on every rule above, with did-you-mean hints.
    - `skills/` — lantern-recipes, phoenix-page-design, lantern-migration,
      lantern-ui-components. Install with `mix lantern_ui.install_skills`.
    - `docs/` — recipes, dense-app, scale (type + grey roles), behaviours.
    """
  end

  defp full_file(version, modules, recipes) do
    """
    # LanternUI #{version} — llms-full.txt

    > Complete model reference. Start with the rules, then the per-module
    > component sections. No React, no JS UI libraries — server-rendered HEEx.

    #{rules_section()}

    ## Components by module

    #{modules_section(modules)}

    ## Copy-paste recipes

    From docs/recipes.md and README.md (same sources the recipe tests render).

    #{recipes_section(recipes)}

    #{deprecations_section()}

    #{tokens_section()}
    """
  end

  defp rules_section do
    """
    ## Rules for AI assistants

    1. Never switch to React or a JS component library. Build with LanternUI
       components in HEEx.
    2. Grouped lists and group headers are banned. One flat list: a status
       column on each row, rows ordered by status then recency, counts in the
       rows or in filter chips. Whatever a group header would have said stays
       visible per row or in the chips.
    3. Never hand-roll a table or button element where a component exists:
       table/1, data_table/1, resource_list/1 for tables; button/1
       (size="icon" for icon-only) or dialog action slots for buttons.
    4. Never use palette color classes (red-500, slate-200) or hex-in-class
       (bg-[#fff]). Use semantic tokens: text-foreground, -soft, -softest,
       text-muted-foreground, text-danger, bg-success, and friends.
    5. Never use arbitrary pixel values (text-[11px], w-[320px]). Dense chrome
       is text-meta (11px), text-caption (12px), text-mono-meta. The
       text-foreground-softer alias is deprecated; use text-foreground-soft.
    6. Copy the recipe HEEx below wherever a recipe fits. Never hand-roll
       rows, glyphs, rings, or rails.
    7. Page layout: title and actions live in the breadcrumb bar; no tabs as a
       default grouping mechanism; data_table fill only inside a bounded-height
       parent; row click opens the record's own route; disable checkboxes when
       there is no bulk action.
    8. Run `mix lantern.lint` on new code. Unknown component or attribute
       names get a did-you-mean hint — trust it over a guess.
    """
  end

  defp catalog_compact(modules) do
    modules
    |> Enum.map(fn %{module: mod, components: components} ->
      rows =
        components
        |> Enum.map(fn %{name: name, doc: doc} -> "- `#{name}/1` — #{doc}" end)
        |> Enum.join("\n")

      "### #{inspect(mod)}\n\n#{rows}"
    end)
    |> Enum.join("\n\n")
  end

  defp modules_section(modules) do
    modules
    |> Enum.map(fn %{module: mod, summary: summary, components: components} ->
      rendered =
        components
        |> Enum.map(&component_section/1)
        |> Enum.join("\n\n")

      "### #{inspect(mod)}\n\n#{summary}\n\n#{rendered}"
    end)
    |> Enum.join("\n\n")
  end

  defp component_section(%{name: name, doc: doc, attrs: attrs, slots: slots}) do
    attr_lines =
      case attrs do
        [] ->
          ["- (no attributes)"]

        _ ->
          Enum.map(attrs, fn attr ->
            qualifiers =
              [
                attr.type,
                if(attr.required, do: "required"),
                attr.values && "values: #{attr.values}",
                attr.default && "default #{attr.default}"
              ]
              |> Enum.reject(&is_nil/1)
              |> Enum.join(", ")

            "- `#{attr.name}` (#{qualifiers}) — #{attr.doc}"
          end)
      end

    slot_lines =
      case slots do
        [] ->
          []

        _ ->
          [
            "Slots:"
            | Enum.map(slots, fn slot ->
                inner =
                  case slot.attrs do
                    [] ->
                      ""

                    slot_attrs ->
                      attrs_text =
                        slot_attrs
                        |> Enum.map(&"  - `#{&1.name}` — #{&1.doc}")
                        |> Enum.join("\n")

                      "\n#{attrs_text}"
                  end

                "- `:#{slot.name}`#{if slot.required, do: " (required)", else: ""} — #{slot.doc}#{inner}"
              end)
          ]
      end

    """
    #### `#{name}/1`

    #{doc}

    #{Enum.join(attr_lines ++ slot_lines, "\n")}
    """
    |> String.trim_trailing()
  end

  defp recipes_section(recipes) do
    recipes
    |> Enum.map(fn %{source: source, heading: heading, code: code} ->
      title = if heading, do: " (#{heading})", else: ""

      "From `#{source}`#{title}:\n\n```heex\n#{code}\n```"
    end)
    |> Enum.join("\n\n")
  end

  defp deprecations_section do
    deprecated =
      LanternUI.Deprecated.deprecated()
      |> Enum.map(fn entry ->
        "- `#{entry.component}/1` is deprecated (removed in 0.9.0); use #{entry.replacement}. Evidence: #{entry.evidence}."
      end)
      |> Enum.join("\n")

    confusables =
      LanternUI.Deprecated.confusables()
      |> Enum.map(fn entry ->
        "- `#{entry.guess}` does not exist; use #{entry.suggestion}. Evidence: #{entry.evidence}."
      end)
      |> Enum.join("\n")

    """
    ## Overlaps and deprecations

    Deprecated (warn at render, removed in 0.9.0 — deprecate, never remove
    without a major version):

    #{deprecated}

    Names models guess that never existed (the lint answers these with
    did-you-mean):

    #{confusables}

    Not duplicates, do not merge: table/1 vs data_table/1 vs resource_list/1
    are tiers (plain table, full list machinery, small index — see the page
    design skill); modal/1 vs alert_dialog/1 vs sheet/1 are purposes
    (general dialog, destructive confirm, edge panel); progress/1 covers bar
    and ring via shape; tabs_list/1 covers segmented via variant.
    """
  end

  defp tokens_section do
    """
    ## Tokens

    Type scale: text-meta (11px), text-caption (12px), text-mono-meta.
    Grey roles: text-foreground, text-foreground-soft, text-foreground-softest,
    text-muted-foreground. Semantic: text-danger, bg-danger, text-success,
    bg-success, text-warning, bg-warning. Components read --lantern-* CSS
    variables chained to host tokens; see README theming and docs/scale.md.
    Data-attribute behaviours (list keyboard nav, persist, collapse) install
    on JS import; see docs/behaviours.md. Hooks bundle:
    priv/static/lantern_ui_hooks.js.
    """
  end
end
