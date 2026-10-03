defmodule Mix.Tasks.LanternUi.InstallSkills do
  @shortdoc "Install lantern skills and agent rules into a consuming app"

  @moduledoc """
  Copy the lantern skills and the `priv/AGENTS.md` rules block into an app:

      mix lantern_ui.install_skills
      mix lantern_ui.install_skills ../my-app
      mix lantern_ui.install_skills --force   # overwrite changed skill files

  Skills go to `<target>/skills/<name>/SKILL.md`. The rules land in
  `<target>/AGENTS.md` between `lantern-ui:rules` markers — re-running
  refreshes that block (with a freshly generated component catalog) and never
  touches anything outside it. Existing skill files are skipped unless
  `--force` is given.
  """

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    {opts, paths} = OptionParser.parse!(args, strict: [force: :boolean])

    target =
      case paths do
        [] -> File.cwd!()
        [path] -> Path.expand(path)
        _ -> Mix.raise("mix lantern_ui.install_skills accepts at most one path")
      end

    source =
      case LanternUI.InstallSkills.locate_source(File.cwd!()) do
        {:ok, path} -> path
        {:error, reason} -> Mix.raise("mix lantern_ui.install_skills: #{reason}")
      end

    report = LanternUI.InstallSkills.run(source, target, force: opts[:force] || false)

    for name <- Enum.sort(report.skills.copied), do: Mix.shell().info("skill copied: #{name}")

    for name <- Enum.sort(report.skills.overwritten),
        do: Mix.shell().info("skill overwritten: #{name}")

    for name <- Enum.sort(report.skills.skipped), do: Mix.shell().info("skill skipped: #{name}")
    Mix.shell().info("AGENTS.md #{report.agents}: #{report.agents_path}")
  end
end
