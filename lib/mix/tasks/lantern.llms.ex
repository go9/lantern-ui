defmodule Mix.Tasks.Lantern.Llms do
  @shortdoc "Regenerate llms.txt and llms-full.txt from the component registry"

  @moduledoc """
  Regenerate the model reference files from the component registry, docs, and
  recipes:

      mix lantern.llms
      mix lantern.llms --check   # fail when the checked-in files are stale (CI)

  Must run inside the lantern_ui package directory (it refuses elsewhere so a
  consumer never litters their own repo with lantern's reference files).
  """

  use Mix.Task

  @impl Mix.Task
  def run(args) do
    {opts, _} = OptionParser.parse!(args, strict: [check: :boolean])
    root = File.cwd!()
    ensure_package_root!(root)

    if opts[:check] do
      case LanternUI.Llms.check(root) do
        :ok ->
          Mix.shell().info("lantern.llms: llms.txt + llms-full.txt fresh")

        {:stale, paths} ->
          Mix.raise("lantern.llms: stale #{Enum.join(paths, ", ")} — run mix lantern.llms")
      end
    else
      [short, full] = LanternUI.Llms.write!(root)
      Mix.shell().info("lantern.llms: wrote #{short} + #{full}")
    end
  end

  defp ensure_package_root!(root) do
    app =
      with {:ok, contents} <- File.read(Path.join(root, "mix.exs")),
           [_ | _] = match <- Regex.run(~r/app:\s*:([a-z_]+)/, contents) do
        List.last(match)
      else
        _ -> nil
      end

    unless app == "lantern_ui" do
      Mix.raise("mix lantern.llms runs inside the lantern_ui package, not #{root}")
    end
  end
end
