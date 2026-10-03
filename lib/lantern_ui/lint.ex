defmodule LanternUI.Lint do
  @moduledoc """
  Scan `.ex` / `.exs` / `.heex` for arbitrary Tailwind pixel values, hardcoded
  palette colors, page-local greys, banned grouped-list markup, hand-rolled
  tables/buttons, deprecated components, and unknown component/attr names with
  "did you mean" hints. Used by `mix lantern.lint`.
  """

  @extensions MapSet.new(~w(.ex .exs .heex))
  @skip_dirs MapSet.new(~w(deps _build node_modules .git cover doc .elixir_ls .elixir-tools))

  @arbitrary_text ~r/(?<![a-z-])(?:[a-z0-9-]+:)*text-\[(\d+(?:\.\d+)?)px\]/
  @arbitrary_box ~r/(?<![a-z-])(?:[a-z0-9-]+:)*(?:max-|min-)?(?:w|h|size)-\[(\d+(?:\.\d+)?)px\]/
  @hex_color ~r/(?<![a-z-])(?:[a-z0-9-]+:)*(?:text|bg|border|ring|fill|stroke|from|to|via|outline|decoration|caret|accent|shadow|divide)-\[#[0-9a-fA-F]{3,8}\]/
  @palette_color ~r/(?<![a-z-])(?:[a-z0-9-]+:)*(?:text|bg|border|ring|fill|stroke|from|to|via|outline|decoration|caret|accent|shadow|divide)-(?:slate|gray|zinc|neutral|stone|red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose)-\d{2,3}\b/

  @group_band ~r/group_band|GroupBand|group-band/
  @raw_table ~r/<table[\s>]/
  @raw_button ~r/<button[\s>]/
  @lantern_table_call ~r/<\.(table|data_table|resource_list)\b/
  @component_call ~r/<\.([a-z][a-z0-9_]*[!?]?)\b/
  @local_def ~r/defp?\s+([a-z][a-z0-9_]*[!?]?)[\s(]/
  @component_call ~r/<\.([a-z][a-z0-9_]*[!?]?)\b/
  # Opening tag up to the first unquoted `>`, `.`s flag for multiline tags.
  @open_tag ~r/<\.([a-z][a-z0-9_]*[!?]?)((?:[^>"']|"[^"]*"|'[^']*')*)>/
  @attr_token ~r/(?:^|\s)([a-zA-Z_:][a-zA-Z0-9_:.-]*)=/

  # Phoenix/LiveView core components: never lantern names, never flagged.
  @phoenix_core ~w(form link inputs_for live_title live_component dynamic_tag portal focus_wrap async_result)

  @doc """
  Walk `root` and return a list of finding maps.

  Options:

    * `:config` — path to a JSON allowlist file. Defaults to
      `root/.lantern-lint.json` when that file exists.
  """
  def scan(root, opts \\ []) do
    root = Path.expand(root)
    config = load_config(root, opts)
    inv = inventory()

    root
    |> list_files(config)
    |> Enum.flat_map(&scan_file(&1, root, config, inv))
    |> Enum.sort_by(&{&1.path, &1.line, &1.column})
  end

  @doc false
  def count_by_rule(findings) do
    Enum.reduce(findings, %{}, fn finding, acc ->
      Map.update(acc, finding.rule, 1, &(&1 + 1))
    end)
  end

  defp load_config(root, opts) do
    path =
      case Keyword.get(opts, :config) do
        nil -> Path.join(root, ".lantern-lint.json")
        given -> Path.expand(given)
      end

    raw =
      if File.exists?(path) do
        path |> File.read!() |> Jason.decode!()
      else
        %{}
      end

    %{
      exclude: List.wrap(raw["exclude"]),
      allow: List.wrap(raw["allow"]),
      allow_rules: allow_rules(raw["allow_rules"] || %{})
    }
  end

  # Rule-scoped allowlist: `%{"hand_button" => ["lib/vendor/**"]}` skips one
  # rule in vendored/component-internal files without blinding the other
  # rules there. Unknown rule names are ignored.
  @configurable_rules ~w(arbitrary_text_size arbitrary_box palette_color hex_color group_band hand_table hand_button deprecated_component unknown_component unknown_attr)

  defp allow_rules(raw) when is_map(raw) do
    Map.new(@configurable_rules, fn rule ->
      {String.to_atom(rule), List.wrap(raw[rule])}
    end)
  end

  defp allow_rules(_), do: allow_rules(%{})

  defp list_files(root, config), do: list_files(root, root, config)

  defp list_files(dir, root, config) do
    case File.ls(dir) do
      {:ok, names} ->
        Enum.flat_map(names, fn name ->
          path = Path.join(dir, name)
          rel = Path.relative_to(path, root)

          cond do
            name in @skip_dirs -> []
            excluded?(rel, config.exclude) -> []
            File.dir?(path) -> list_files(path, root, config)
            Path.extname(name) in @extensions -> [path]
            true -> []
          end
        end)

      {:error, _} ->
        []
    end
  end

  defp scan_file(path, root, config, inv) do
    rel = Path.relative_to(path, root)

    if allowed?(rel, config.allow) do
      []
    else
      source = File.read!(path)
      lines = String.split(source, "\n")
      local = local_defs(source)

      line_findings =
        lines
        |> Enum.with_index(1)
        |> Enum.flat_map(fn {text, n} ->
          prev = if n > 1, do: Enum.at(lines, n - 2), else: ""

          if ignored_line?(text, prev) do
            []
          else
            findings_on_line(rel, n, text, inv, local, config)
          end
        end)

      line_findings ++ source_findings(rel, source, lines, inv, config)
    end
  end

  defp ignored_line?(text, prev) do
    String.contains?(text, "lantern-lint:ignore") or
      String.contains?(to_string(prev), "lantern-lint:ignore")
  end

  defp findings_on_line(rel, n, text, inv, local, config) do
    [
      {@arbitrary_text, :arbitrary_text_size},
      {@arbitrary_box, :arbitrary_box},
      {@palette_color, :palette_color},
      {@hex_color, :hex_color},
      {@group_band, :group_band}
    ]
    |> Enum.reject(fn {_regex, rule} -> rule_skipped?(config, rel, rule) end)
    |> Enum.flat_map(fn {regex, rule} -> collect(rel, n, text, regex, rule) end)
    |> Kernel.++(component_findings(rel, n, text, inv, local, config))
  end

  defp collect(rel, n, text, regex, rule) do
    regex
    |> Regex.scan(text, return: :index)
    |> Enum.map(fn [{start, len} | _] ->
      match = binary_part(text, start, len)

      %{
        path: rel,
        line: n,
        column: start + 1,
        rule: rule,
        match: match,
        hint: hint(rule, match)
      }
    end)
  end

  @doc false
  # `%{name => %{attrs: [String.t()], has_rest: boolean, deprecated: String.t() | nil}}`.
  # Unknown to the registry (custom app components, Phoenix core) is absent.
  def inventory do
    deprecated =
      Map.new(LanternUI.Deprecated.deprecated(), fn entry ->
        {Atom.to_string(entry.component), entry.replacement}
      end)

    for {_key, mod} <- LanternUI.__components__(),
        {name, spec} <- mod.__components__(),
        {fname, 1} <- mod.__info__(:functions),
        fname == name,
        into: %{} do
      sname = Atom.to_string(name)

      {
        sname,
        %{
          attrs: Enum.map(spec.attrs, &Atom.to_string(&1.name)),
          has_rest: Enum.any?(spec.attrs, &(&1.name == :rest)),
          deprecated: Map.get(deprecated, sname)
        }
      }
    end
  end

  defp confusables do
    Map.new(LanternUI.Deprecated.confusables(), fn entry ->
      {entry.guess, entry.suggestion}
    end)
  end

  # `<.name` call on one line: deprecated-use, confusable, or did-you-mean.
  # Names defined in the same file (`def`/`defp`, e.g. a module's own private
  # sub-components like `<.sep>`) are local, never guesses.
  defp component_findings(rel, n, text, inv, local, config) do
    @component_call
    |> Regex.scan(text, return: :index)
    |> Enum.flat_map(fn [{start, len}, {ns, nl}] ->
      name = binary_part(text, ns, nl)
      match = binary_part(text, start, len)

      with false <- MapSet.member?(local, name),
           {rule, hint} <- check_component(name, inv),
           false <- rule_skipped?(config, rel, rule) do
        [%{path: rel, line: n, column: start + 1, rule: rule, match: match, hint: hint}]
      else
        _ -> []
      end
    end)
  end

  defp local_defs(source) do
    @local_def
    |> Regex.scan(source, capture: :all_but_first)
    |> List.flatten()
    |> MapSet.new()
  end

  defp check_component(name, inv) do
    cond do
      Map.has_key?(inv, name) ->
        case inv[name].deprecated do
          nil -> nil
          replacement -> {:deprecated_component, "deprecated; use #{replacement} instead"}
        end

      name in @phoenix_core ->
        nil

      Map.has_key?(confusables(), name) ->
        {:unknown_component, "unknown component <.#{name}>; use #{confusables()[name]}"}

      suggestion = suggest(name, Map.keys(inv)) ->
        {:unknown_component, "unknown component <.#{name}>; did you mean <.#{suggestion}>?"}

      true ->
        nil
    end
  end

  # Whole-file rules: hand-rolled buttons/tables (raw elements can open
  # across lines, so these match on the source and map back to lines) and
  # unknown attrs on components strict enough to declare every attr (no `:rest`).
  # Tables follow eval semantics: a raw `<table>` is only a finding when the
  # file uses no lantern table component.
  defp source_findings(rel, source, lines, inv, config) do
    source_collect(rel, source, lines, @raw_button, :hand_button, config) ++
      hand_table_findings(rel, source, lines, config) ++
      unknown_attr_findings(rel, source, lines, inv, config)
  end

  defp source_collect(rel, source, lines, regex, rule, config) do
    if rule_skipped?(config, rel, rule) do
      []
    else
      do_source_collect(rel, source, lines, regex, rule)
    end
  end

  defp rule_skipped?(config, rel, rule) do
    config |> rule_globs(rule) |> Enum.any?(&path_match?(rel, &1))
  end

  defp rule_globs(config, rule) do
    config |> Map.get(:allow_rules, %{}) |> Map.get(rule, [])
  end

  defp do_source_collect(rel, source, lines, regex, rule) do
    regex
    |> Regex.scan(source, return: :index)
    |> Enum.flat_map(fn [{start, len} | _] ->
      match = binary_part(source, start, len)
      {line, column} = line_column(lines, start)
      prev = if line > 1, do: Enum.at(lines, line - 2), else: ""
      text = Enum.at(lines, line - 1, "")

      if ignored_line?(text, prev) do
        []
      else
        [%{path: rel, line: line, column: column, rule: rule, match: match, hint: hint(rule, match)}]
      end
    end)
  end

  defp hand_table_findings(rel, source, lines, config) do
    if rule_skipped?(config, rel, :hand_table) or Regex.match?(@lantern_table_call, source) do
      []
    else
      do_source_collect(rel, source, lines, @raw_table, :hand_table)
    end
  end

  defp unknown_attr_findings(rel, source, lines, inv, config) do
    if rule_skipped?(config, rel, :unknown_attr) do
      []
    else
      @open_tag
      |> Regex.scan(source, return: :index)
      |> Enum.flat_map(fn [{start, _}, {ns, nl}, {_as, al} = attrs_idx] ->
        name = binary_part(source, ns, nl)
        attrs = binary_part(source, elem(attrs_idx, 0), al)
        check_attrs(rel, source, lines, start, name, attrs, inv)
      end)
    end
  end

  defp check_attrs(rel, source, lines, tag_offset, name, attrs, inv) do
    with %{has_rest: false, attrs: known} <- Map.get(inv, name),
         [_ | _] = unknown <- attr_names(attrs) -- known do
      Enum.flat_map(unknown, fn attr ->
        offset = attr_offset(source, tag_offset, attrs, attr)
        {line, column} = line_column(lines, offset)

        hint =
          case suggest(attr, known) do
            nil -> "unknown attr #{attr} on <.#{name}>"
            suggestion -> "unknown attr #{attr} on <.#{name}>; did you mean #{suggestion}?"
          end

        [%{path: rel, line: line, column: column, rule: :unknown_attr, match: attr, hint: hint}]
      end)
    else
      _ -> []
    end
  end

  defp attr_names(attrs) do
    @attr_token
    |> Regex.scan(attrs, capture: :all_but_first)
    |> List.flatten()
    |> Enum.reject(&(String.starts_with?(&1, ":") or String.contains?(&1, "-")))
    |> Enum.uniq()
  end

  # Byte offset of `attr=` inside the tag's attr string, relative to the file.
  defp attr_offset(source, tag_offset, attrs, attr) do
    tag = binary_part(source, tag_offset, byte_size(source) - tag_offset)
    inner_offset = :binary.match(tag, attrs) |> elem(0)

    case :binary.match(attrs, attr <> "=") do
      {pos, _} -> tag_offset + inner_offset + pos
      :nomatch -> tag_offset
    end
  end

  defp line_column(lines, offset) do
    {line, line_start} =
      lines
      |> Enum.with_index(1)
      |> Enum.reduce_while({1, 0}, fn {text, n}, {_line, start} ->
        if offset < start + byte_size(text) + 1 do
          {:halt, {n, start}}
        else
          {:cont, {n + 1, start + byte_size(text) + 1}}
        end
      end)

    {line, offset - line_start + 1}
  end

  # A suggestion when the guess is a prefix of the candidate (or vice versa),
  # else on a close Jaro match with a small length difference — so `<.stat>`
  # finds `<.stat_card>` but a custom `<.my_modal>` stays silent.
  defp suggest(guess, candidates) do
    prefixed =
      Enum.filter(candidates, fn candidate ->
        String.starts_with?(candidate, guess) or String.starts_with?(guess, candidate)
      end)

    case Enum.sort_by(prefixed, &byte_size/1) do
      [best | _] when best != guess -> best
      _ -> closest(guess, candidates)
    end
  end

  defp closest(guess, candidates) do
    scored =
      candidates
      |> Enum.map(&{String.jaro_distance(guess, &1), abs(byte_size(guess) - byte_size(&1)), &1})
      |> Enum.filter(fn {score, diff, candidate} ->
        candidate != guess and score >= 0.85 and diff <= 2
      end)
      |> Enum.sort()

    case scored do
      [{_, _, best} | _] -> best
      [] -> nil
    end
  end

  defp hint(:arbitrary_text_size, match) do
    case Regex.run(~r/(\d+(?:\.\d+)?)px/, match) do
      [_, "11"] -> "use text-meta (11px) or text-mono-meta for ids"
      [_, "12"] -> "use text-caption (12px)"
      _ -> "use text-meta, text-caption, or text-mono-meta"
    end
  end

  defp hint(:arbitrary_box, _match) do
    "use a named size, rem, or a layout token — not an arbitrary pixel box"
  end

  defp hint(:palette_color, _match) do
    "use a semantic token (text-foreground-soft, text-danger, bg-success, …)"
  end

  defp hint(:hex_color, _match) do
    "use a grey role (foreground / soft / softest / muted-foreground), not a page-local hex"
  end

  defp hint(:group_band, _match) do
    "grouped lists are banned; use one flat list with a status column + filter chips (see docs/recipes.md)"
  end

  defp hint(:hand_table, _match) do
    "hand-rolled <table>; use table/1, data_table/1, or resource_list/1"
  end

  defp hint(:hand_button, _match) do
    ~s|hand-rolled <button>; use button/1 (size="icon" for icon-only) or a dialog action slot|
  end

  defp allowed?(rel, allows), do: Enum.any?(allows, &path_match?(rel, &1))
  defp excluded?(rel, excludes), do: Enum.any?(excludes, &path_match?(rel, &1))

  defp path_match?(rel, pattern) do
    rel == pattern or glob_match?(pattern, rel)
  end

  defp glob_match?(pattern, path) do
    regex =
      pattern
      |> Regex.escape()
      |> String.replace("\\*\\*", "\x00")
      |> String.replace("\\*", "[^/]*")
      |> String.replace("\x00", ".*")
      |> then(&Regex.compile!("^#{&1}$"))

    Regex.match?(regex, path)
  end
end
