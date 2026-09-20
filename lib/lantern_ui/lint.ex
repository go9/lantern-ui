defmodule LanternUI.Lint do
  @moduledoc """
  Scan `.ex` / `.exs` / `.heex` for arbitrary Tailwind pixel values, hardcoded
  palette colors, and page-local greys. Used by `mix lantern.lint`.
  """

  @extensions MapSet.new(~w(.ex .exs .heex))
  @skip_dirs MapSet.new(~w(deps _build node_modules .git cover doc .elixir_ls .elixir-tools))

  @arbitrary_text ~r/(?<![a-z-])(?:[a-z0-9-]+:)*text-\[(\d+(?:\.\d+)?)px\]/
  @arbitrary_box ~r/(?<![a-z-])(?:[a-z0-9-]+:)*(?:max-|min-)?(?:w|h|size)-\[(\d+(?:\.\d+)?)px\]/
  @hex_color ~r/(?<![a-z-])(?:[a-z0-9-]+:)*(?:text|bg|border|ring|fill|stroke|from|to|via|outline|caret|accent)-\[#[0-9a-fA-F]{3,8}\]/
  @palette_color ~r/(?<![a-z-])(?:[a-z0-9-]+:)*(?:text|bg|border|ring|fill|stroke|from|to|via|outline|decoration|caret|accent|shadow|divide)-(?:slate|gray|zinc|neutral|stone|red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose)-\d{2,3}\b/

  @doc """
  Walk `root` and return a list of finding maps.

  Options:

    * `:config` — path to a JSON allowlist file. Defaults to
      `root/.lantern-lint.json` when that file exists.
  """
  def scan(root, opts \\ []) do
    root = Path.expand(root)
    config = load_config(root, opts)

    root
    |> list_files(config)
    |> Enum.flat_map(&scan_file(&1, root, config))
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
      allow: List.wrap(raw["allow"])
    }
  end

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

  defp scan_file(path, root, config) do
    rel = Path.relative_to(path, root)

    if allowed?(rel, config.allow) do
      []
    else
      lines = path |> File.read!() |> String.split("\n")

      lines
      |> Enum.with_index(1)
      |> Enum.flat_map(fn {text, n} ->
        prev = if n > 1, do: Enum.at(lines, n - 2), else: ""

        if ignored_line?(text, prev) do
          []
        else
          findings_on_line(rel, n, text)
        end
      end)
    end
  end

  defp ignored_line?(text, prev) do
    String.contains?(text, "lantern-lint:ignore") or
      String.contains?(to_string(prev), "lantern-lint:ignore")
  end

  defp findings_on_line(rel, n, text) do
    [
      {@arbitrary_text, :arbitrary_text_size},
      {@arbitrary_box, :arbitrary_box},
      {@palette_color, :palette_color},
      {@hex_color, :hex_color}
    ]
    |> Enum.flat_map(fn {regex, rule} -> collect(rel, n, text, regex, rule) end)
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
