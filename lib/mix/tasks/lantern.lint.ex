defmodule Mix.Tasks.Lantern.Lint do
  @shortdoc "Fail on arbitrary Tailwind px values, palette colors, and page-local greys"

  @moduledoc """
  Scan `.ex` / `.exs` / `.heex` for values that bypass lantern's compact type
  and grey scale. See `docs/scale.md`.

      mix lantern.lint
      mix lantern.lint ../some-app
      mix lantern.lint --format json

  Allowlist: `.lantern-lint.json` (`exclude` / `allow` globs) or a
  `lantern-lint:ignore` comment on the same line or the line above.
  """

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    {opts, paths} =
      OptionParser.parse!(args, strict: [format: :string, config: :string])

    root =
      case paths do
        [] -> File.cwd!()
        [path] -> Path.expand(path)
        _ -> Mix.raise("mix lantern.lint accepts at most one path")
      end

    unless File.dir?(root) do
      Mix.raise("mix lantern.lint: not a directory: #{root}")
    end

    findings = LanternUI.Lint.scan(root, config: opts[:config])
    format = opts[:format] || "text"

    print(findings, format)

    if findings != [] do
      exit({:shutdown, 1})
    end
  end

  defp print(findings, "json") do
    payload = %{
      findings:
        Enum.map(findings, fn finding ->
          %{
            path: finding.path,
            line: finding.line,
            column: finding.column,
            rule: finding.rule,
            match: finding.match,
            hint: finding.hint
          }
        end),
      counts: LanternUI.Lint.count_by_rule(findings),
      total: length(findings)
    }

    Mix.shell().info(Jason.encode!(payload, pretty: true))
  end

  defp print([], _format) do
    Mix.shell().info("lantern.lint: 0 findings")
  end

  defp print(findings, _format) do
    Enum.each(findings, fn finding ->
      Mix.shell().info(
        "#{finding.path}:#{finding.line}:#{finding.column}: #{finding.rule} #{finding.match}  (#{finding.hint})"
      )
    end)

    counts =
      findings
      |> LanternUI.Lint.count_by_rule()
      |> Enum.map(fn {rule, n} -> "#{n} #{rule}" end)
      |> Enum.join(", ")

    Mix.shell().info("lantern.lint: #{length(findings)} finding(s) (#{counts})")
  end
end
