# Usage: elixir eval/checks.exs --expect <literal> [--expect <literal> ...]
#          [--min-comps N] [--block NAME ...] [--lint-findings N] -- <file> ...
#
# Scans ONLY the given files (the runner passes the model's changed files).
# Prints one `RULE: <name> <points>/<max> <detail>` line per rule and a final
# `SCORE: <total>/100` line. Exit 0 always (a zero score is data, not a crash).

defmodule EvalChecks do
  # Step-2 inventory (flicker #3415): deprecated names (icon_button,
  # segmented, progress_ring, property_row — see LanternUI.Deprecated) and the
  # never-existent donut_chart no longer score; the prompts steer to the
  # replacements. Baseline results/baseline-2026-10-03.md keep the old list.
  @lantern_components ~w(
    button badge card table data_table resource_list modal alert_dialog
    toast_group form input select checkbox radio switch textarea command dropdown menu
    popover calendar date_picker datetime_field breadcrumb empty_state
    description_list layout tabs pagination list_row status_glyph priority_glyph
    progress state_glyph icon avatar loading skeleton
    sheet side_panel inspector navlist tooltip accordion autocomplete
    color_input log_view message message_scroller meter scroll_area slider
    timeline waterfall stat_card stat_grid area_chart bar_chart line_chart sparkline
  )

  @palette ~r/(?:^|[\s"'([])(?:[a-z0-9-]+:)*(?:text|bg|border|ring|fill|stroke|from|to|via|outline|decoration|caret|accent|shadow|divide)-(?:slate|gray|zinc|neutral|stone|red|orange|amber|yellow|lime|green|emerald|teal|cyan|sky|blue|indigo|violet|purple|fuchsia|pink|rose)-\d{2,3}\b/
  @hex_in_class ~r/(?:text|bg|border|ring|fill|stroke)-\[#[0-9a-fA-F]{3,8}\]/
  @arbitrary_px ~r/-\[\d+(?:\.\d+)?px\]/

  # Blocks-fidelity checks (round 2): the page structure matches a recipe
  # block — breadcrumb-bar title/actions, flat list with status col + chips,
  # stack spacing. Component blocks match local `<.name` AND remote
  # `<Module.name` calls (aliasing lantern modules is valid HEEx); the rest
  # are literal attribute/text patterns.
  @block_components %{
    "breadcrumb" => ~w(breadcrumb page_header),
    "filter-chips" => ~w(tabs_list),
    "flat-list" => ~w(data_table resource_list list_row table),
    "detail-inspector" => ~w(inspector side_panel description_list),
    "form-card" => ~w(form input select textarea checkbox switch),
    "stat-row" => ~w(stat_card stat_grid),
    "chart" => ~w(area_chart bar_chart line_chart sparkline),
    "dialog" => ~w(modal alert_dialog sheet),
    "empty-states" => ~w(empty_state),
    "loading" => ~w(skeleton loading),
    "command" => ~w(command command_group command_item),
    "pagination" => ~w(pagination)
  }

  @block_patterns %{
    "toast" => ~r/toast_group|send_toast/,
    "theme" => ~r/preset="shadcn"|data-lantern-theme/
  }

  defp block_hit?(all, name) do
    cond do
      # Filter chips: segmented tabs_list, or lantern badges/buttons as chips.
      name == "filter-chips" ->
        Regex.match?(~r/<\.tabs_list\b|<[A-Z][A-Za-z0-9_.]*\.tabs_list\b|variant="segmented"/, all)

      Map.has_key?(@block_patterns, name) ->
        Regex.match?(Map.fetch!(@block_patterns, name), all)

      Map.has_key?(@block_components, name) ->
        Enum.any?(Map.fetch!(@block_components, name), fn comp ->
          Regex.match?(~r/<\.#{comp}\b|<[A-Z][A-Za-z0-9_.]*\.#{comp}\b/, all)
        end)

      true ->
        raise "unknown block: #{name}"
    end
  end

  def run(files, expects, opts) do
    sources =
      Enum.map(files, fn f ->
        {f, File.read!(f)}
      end)

    all = Enum.map_join(sources, "\n", &elem(&1, 1))
    Process.put(:eval_sources, sources)

    results = [
      no_group_band(all),
      no_hand_table(all),
      no_hand_button(all),
      no_palette(all),
      no_arbitrary(all),
      lantern_usage(all, Keyword.get(opts, :min_comps, 4)),
      a11y(all),
      deliverables(all, expects)
    ]

    Enum.each(results, fn {name, pts, max, detail} ->
      IO.puts("RULE: #{name} #{pts}/#{max} #{detail}")
    end)

    total = Enum.sum(Enum.map(results, &elem(&1, 1)))
    IO.puts("SCORE: #{total}/100")

    # Gates (round 2 — reported, not part of /100 so round-1 scores stay
    # comparable): lint findings must be 0, every required recipe block
    # must be present.
    blocks = Keyword.get(opts, :blocks, [])
    missing = Enum.reject(blocks, &block_hit?(all, &1))

    if blocks == [] do
      IO.puts("BLOCKS: PASS no blocks required")
    else
      if missing == [] do
        IO.puts("BLOCKS: PASS #{length(blocks)}/#{length(blocks)} #{Enum.join(blocks, ",")}")
      else
        IO.puts("BLOCKS: FAIL missing #{Enum.join(missing, ",")}")
      end
    end

    case Keyword.get(opts, :lint_findings) do
      nil -> IO.puts("LINT: UNKNOWN not measured")
      0 -> IO.puts("LINT: PASS 0 findings")
      n -> IO.puts("LINT: FAIL #{n} findings")
    end
  end

  defp no_group_band(all) do
    hits = Regex.scan(~r/group_band|GroupBand|group-band/i, all) |> length()
    if hits == 0, do: {:no_group_band, 20, 20, "clean"}, else: {:no_group_band, 0, 20, "#{hits} banned hits"}
  end

  defp no_hand_table(all) do
    raw = Regex.scan(~r/<table[\s>]/, all) |> length()
    lantern = Regex.scan(~r/<\.(table|data_table|resource_list)\b/, all) |> length()

    cond do
      raw == 0 -> {:no_hand_table, 15, 15, "no raw <table>"}
      lantern > 0 -> {:no_hand_table, 15, 15, "raw <table> alongside lantern table"}
      true -> {:no_hand_table, 0, 15, "#{raw} hand-rolled <table>, no lantern table"}
    end
  end

  defp no_hand_button(all) do
    hits = Regex.scan(~r/<button[\s>]/, all) |> length()
    if hits == 0, do: {:no_hand_button, 10, 10, "clean"}, else: {:no_hand_button, 0, 10, "#{hits} raw <button>"}
  end

  defp scaled(name, max, hits) do
    pts = cond do
      hits == 0 -> max
      hits <= 2 -> div(max, 2)
      true -> 0
    end
    {name, pts, max, "#{hits} hits"}
  end

  defp no_palette(all) do
    hits = Regex.scan(@palette, all) |> length()
    hits = hits + (Regex.scan(@hex_in_class, all) |> length())
    scaled(:no_palette, 10, hits)
  end

  defp no_arbitrary(all) do
    scaled(:no_arbitrary, 10, Regex.scan(@arbitrary_px, all) |> length())
  end

  defp lantern_usage(all, min) do
    # Local `<.name` and remote `<Module.name` calls both count: models that
    # alias lantern modules emit the latter, and it is valid HEEx.
    # Round 2: the bar scales to the task (manifest `min_comps`).
    used =
      @lantern_components
      |> Enum.uniq()
      |> Enum.filter(&Regex.match?(~r/(?:<\.(?:#{Regex.escape(&1)})\b|<[A-Z][A-Za-z0-9_.]*\.#{Regex.escape(&1)}\b)/, all))

    n = length(used)
    pts = round(15 * min(1.0, n / max(min, 1)))
    {:lantern_usage, pts, 15, "#{n} components (bar #{min}): #{Enum.join(Enum.take(used, 10), ",")}"}
  end

  defp a11y(all) do
    has_inputs =
      Regex.match?(~r/<\.(input|select|checkbox|radio|switch|textarea)\b|<input[\s>]|<select[\s>]|<textarea[\s>]/, all)

    labelled =
      !has_inputs or
        Regex.match?(~r/<label[\s>]|label=/, all)

    icon_buttons = Regex.scan(~r/<\.icon_button\b([^>]*?)>/s, all)

    unlabeled_icon_buttons =
      Enum.count(icon_buttons, fn [_, attrs] ->
        !Regex.match?(~r/aria-label=|label=/, attrs)
      end)

    cond do
      !labelled -> {:a11y, 0, 10, "inputs without labels"}
      unlabeled_icon_buttons > 0 -> {:a11y, 5, 10, "#{unlabeled_icon_buttons} icon_button without label"}
      true -> {:a11y, 10, 10, "ok"}
    end
  end

  defp deliverables(_all, []) do
    {:deliverables, 10, 10, "no expects declared"}
  end

  # Expects starting with "/" are routes: they only count when registered in
  # a router file (a LiveView mentioning its own path is not a route).
  # All other expects (module names) count anywhere in the diff.
  defp deliverables(all, expects) do
    {routes, modules} = Enum.split_with(expects, &String.starts_with?(&1, "/"))
    router_text = for {f, src} <- all_sources(), Path.basename(f) == "router.ex", do: src
    router_all = Enum.join(router_text, "\n")

    found_routes = Enum.count(routes, &String.contains?(router_all, &1))
    found_modules = Enum.count(modules, &String.contains?(all, &1))
    total = length(expects)

    pts = if total == 0, do: 10, else: round(10 * (found_routes + found_modules) / total)
    {:deliverables, pts, 10, "#{found_routes + found_modules}/#{total} expects found"}
  end

  defp all_sources do
    # Rebuilt by run/2 via process dictionary to keep the arity stable.
    Process.get(:eval_sources, [])
  end
end

{expects, opts, files} =
  case Enum.split_while(System.argv(), &(&1 != "--")) do
    {flags, ["--" | rest]} ->
      {exp, opts} =
        flags
        |> Enum.chunk_every(2)
        |> Enum.reduce({[], [min_comps: 4, blocks: [], lint_findings: nil]}, fn
          ["--expect", lit], {e, o} -> {[lit | e], o}
          ["--min-comps", n], {e, o} -> {e, Keyword.put(o, :min_comps, String.to_integer(n))}
          ["--block", name], {e, o} -> {e, Keyword.update!(o, :blocks, &(&1 ++ [name]))}
          ["--lint-findings", n], {e, o} -> {e, Keyword.put(o, :lint_findings, String.to_integer(n))}
          _, acc -> acc
        end)

      {Enum.reverse(exp), opts, rest}

    _ ->
      IO.puts(:stderr, "usage: elixir checks.exs --expect LIT ... [--min-comps N] [--block NAME]... [--lint-findings N] -- <file> ...")
      System.halt(2)
  end

files = Enum.filter(files, &File.regular?/1)

if files == [] do
  IO.puts("RULE: no_files 0/100 no changed files to score")
  IO.puts("SCORE: 0/100")
else
  EvalChecks.run(files, expects, opts)
end
