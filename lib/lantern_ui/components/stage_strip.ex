defmodule LanternUI.Components.StageStrip do
  @moduledoc """
  Compact, ordered stage pips for a workflow summary. Pure server render; no JS.

      <.stage_strip stages={[
        %{label: "Triaged", state: :done},
        %{label: "Drafted", state: :skipped},
        %{label: "Decided", state: :waiting},
        %{label: "In work", state: :pending},
        %{label: "Shipped", state: :pending},
        %{label: "Told", state: :pending}
      ]} />

  The caller owns stage names, order, count and state derivation. Suggestions
  uses six stages; the library does not encode its business rules. Every stage
  needs a nonblank label and one of `:done`, `:active`, `:waiting`, `:pending`,
  `:skipped`, `:failed`. Invalid or empty input raises `ArgumentError`.

  A single `role="img"` exposes every stage and its state as words in its
  generated `aria-label` and `title`; the individual pips are decorative.
  Active reads “in progress” and waiting reads “waiting on you”. This is a
  static summary, with no focus stop, keyboard interaction or animation (also
  under reduced motion). Put it beside a real link to the detailed trace.
  Server patches own all state. Use `timeline` for detail, `waterfall` for
  durations and `progress` for a scalar amount.
  """
  use Phoenix.Component

  alias LanternUI.Class

  @state_words %{
    done: "done",
    active: "in progress",
    waiting: "waiting on you",
    pending: "pending",
    skipped: "skipped",
    failed: "failed"
  }

  attr(:stages, :list,
    required: true,
    doc: "Nonempty ordered list of `%{label: string, state: atom}`. See module docs for states."
  )

  attr(:class, :any, default: nil, doc: "Extra classes merged onto the root.")
  attr(:rest, :global, doc: "HTML/`phx-*` attrs. Keep the generated role and accessible label.")

  def stage_strip(assigns) do
    summary = summary!(assigns.stages)
    assigns = assign(assigns, :summary, summary)

    ~H"""
    <span
      class={Class.merge(["lui-stage-strip", @class])}
      role="img"
      aria-label={"Progress: #{@summary}"}
      title={@summary}
      {@rest}
    >
      <span
        :for={stage <- @stages}
        class="lui-stage-strip-pip"
        data-state={stage.state}
        aria-hidden="true"
      ></span>
    </span>
    """
  end

  defp summary!([_ | _] = stages) do
    Enum.map_join(stages, ", ", fn
      %{label: label, state: state} when is_binary(label) and is_map_key(@state_words, state) ->
        if String.trim(label) == "", do: invalid_stage!()
        "#{label} #{Map.fetch!(@state_words, state)}"

      _ ->
        invalid_stage!()
    end)
  end

  defp summary!(_), do: invalid_stage!()

  defp invalid_stage! do
    raise ArgumentError,
          "stage_strip requires nonempty stages with nonblank labels and states done/active/waiting/pending/skipped/failed"
  end
end
