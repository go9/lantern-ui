defmodule LanternUI.Deprecated do
  @moduledoc """
  Deprecation registry for overlapping LanternUI APIs.

  `deprecated/0` lists components that still render until their `removed_in`
  version (each call site also warns via `warn/3`). `confusables/0` lists names that
  never existed but models guess anyway, with the evidence that proves the
  confusion is real. Both feed `mix lantern.lint` hints and the generated
  `llms.txt`, so there is one source of truth for "use X instead of Y".
  """
  require Logger

  @doc """
  Emit a deprecation warning once per BEAM node per component name.

  `removed_in` is the version the component goes away in; it defaults to
  `"0.9.0"` for the entries that were deprecated before removal dates moved to
  the registry.
  """
  def warn(component, replacement, removed_in \\ "0.9.0")
      when is_atom(component) and is_binary(replacement) and is_binary(removed_in) do
    key = {__MODULE__, component}

    unless :persistent_term.get(key, false) do
      :persistent_term.put(key, true)

      Logger.warning(
        "LanternUI #{component}/1 is deprecated and will be removed in #{removed_in}; use #{replacement} instead"
      )
    end

    :ok
  end

  @doc """
  Deprecated components: `%{component, replacement, since, removed_in, evidence}`.
  `since` is the first release that deprecated the component. `removed_in` is the
  planned removal version, or `nil` when no removal is scheduled.

  Every entry has a `@deprecated` annotation on the component itself and warns
  through `warn/3` at render time. Lint flags call sites. An entry is not removed
  before its `removed_in` version.
  """
  def deprecated do
    [
      %{
        component: :icon_button,
        replacement: ~s|<.button size="icon" label="...">|,
        since: "0.8.2",
        removed_in: nil,
        evidence: "eval tasks 01/05 steer models to icon_button; same chrome as button/1"
      },
      %{
        component: :segmented,
        replacement: ~s|<.tabs_list variant="segmented">|,
        since: "0.8.2",
        removed_in: nil,
        evidence: "eval tasks 01 + brief steer models to segmented; duplicate filter-chip API"
      },
      %{
        component: :progress_ring,
        replacement: ~s|<.progress shape="ring" ...>|,
        since: "0.8.2",
        removed_in: nil,
        evidence: ~s|duplicate of progress/1 shape="ring"; both in eval inventory|
      },
      %{
        component: :property_row,
        replacement: ~s|<.description_list layout="dense"> with <:item>|,
        since: "0.8.2",
        removed_in: nil,
        evidence:
          "eval task 03 steers models to property_row; same rows as dense description_list"
      },
      %{
        component: :page_header,
        replacement: "<.page_shell>",
        since: "0.10",
        removed_in: "1.0",
        evidence:
          "shell contract 0.10: page_header draws a second visible title row under the breadcrumb; page_shell makes the breadcrumb the one title (docs/recipes.md Block 1)"
      }
    ]
  end

  @doc """
  Guessed-but-nonexistent names: `{guess, suggestion, evidence}`.

  The guesses come from the step-1 eval baseline (`eval/results/baseline-2026-10-03.md`
  run notes): models wrote these names from HexDocs alone, so the lint gives a
  precise "did you mean" instead of a compile error.
  """
  def confusables do
    [
      %{
        guess: "stat",
        suggestion: "<.stat_card> for one metric, <.stat_grid> for a group",
        evidence: "baseline 2026-10-03 run notes (stat→stat_card prompt fix)"
      },
      %{
        guess: "toast",
        suggestion: "<.toast_group> on the page + LanternUI.send_toast/3",
        evidence: "baseline 2026-10-03 run notes; eval tasks 02/05/08/09"
      }
    ]
  end
end
