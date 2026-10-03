defmodule LanternUI.InstallSkills do
  @moduledoc """
  Copies the lantern agent skills and rules into a consuming app.

  Safe to re-run: skill files that already exist are left alone unless
  `:force` is given, and the `AGENTS.md` block is replaced in place between
  its markers — user content outside the markers is never touched.

  Skills land in `<target>/skills/<name>/SKILL.md` (the same layout this
  package uses, so skill imports keep working). The rules block comes from
  `priv/AGENTS.md` with its catalog section rendered from the live registry,
  so the installed catalog can never rot.
  """

  @skills ~w(lantern-migration lantern-recipes lantern-ui-components phoenix-page-design)
  @start_marker "<!-- lantern-ui:rules:start -->"
  @end_marker "<!-- lantern-ui:rules:end -->"
  @catalog_start "<!-- lantern-ui:catalog:start -->"
  @catalog_end "<!-- lantern-ui:catalog:end -->"

  @doc """
  Install from package `source` into app `target`.

  Options: `:force` (overwrite changed skill files). Returns a report map.
  """
  def run(source, target, opts \\ []) do
    force = Keyword.get(opts, :force, false)
    File.mkdir_p!(target)

    skills_report = install_skills(source, target, force)
    {agents_status, agents_path} = install_agents(source, target)

    %{skills: skills_report, agents: agents_status, agents_path: agents_path}
  end

  @doc """
  Locate the lantern_ui package source: the installed dep in consumer apps,
  the working tree when run inside this package.
  """
  def locate_source(cwd \\ File.cwd!()) do
    deps =
      try do
        Mix.Project.deps_paths()
      rescue
        _ -> %{}
      end

    dep_path = deps[:lantern_ui]

    cond do
      is_binary(dep_path) and File.dir?(Path.join(dep_path, "skills")) -> {:ok, dep_path}
      package_root?(cwd) -> {:ok, cwd}
      true -> {:error, "cannot locate the lantern_ui package source"}
    end
  end

  @doc """
  Render the `priv/AGENTS.md` template: the catalog section becomes a table
  generated from the live component registry.
  """
  def render_agents(template) do
    [before, rest] = String.split(template, @catalog_start, parts: 2)
    [_old, after_catalog] = String.split(rest, @catalog_end, parts: 2)

    before <> @catalog_start <> "\n" <> catalog_table() <> @catalog_end <> after_catalog
  end

  defp install_skills(source, target, force) do
    Enum.reduce(@skills, %{copied: [], skipped: [], overwritten: []}, fn name, acc ->
      content = File.read!(Path.join([source, "skills", name, "SKILL.md"]))
      dest = Path.join([target, "skills", name, "SKILL.md"])
      File.mkdir_p!(Path.dirname(dest))

      case File.read(dest) do
        {:ok, ^content} ->
          Map.update!(acc, :skipped, &[name | &1])

        {:ok, _} when not force ->
          Map.update!(acc, :skipped, &[name | &1])

        {:ok, _} ->
          File.write!(dest, content)
          Map.update!(acc, :overwritten, &[name | &1])

        {:error, _} ->
          File.write!(dest, content)
          Map.update!(acc, :copied, &[name | &1])
      end
    end)
  end

  defp install_agents(source, target) do
    block =
      source
      |> Path.join("priv/AGENTS.md")
      |> File.read!()
      |> render_agents()
      |> extract_block()

    dest = Path.join(target, "AGENTS.md")

    case File.read(dest) do
      {:error, _} ->
        File.write!(dest, block <> "\n")
        {:created, dest}

      {:ok, existing} ->
        if String.contains?(existing, @start_marker) and String.contains?(existing, @end_marker) do
          File.write!(dest, replace_block(existing, block))
          {:updated, dest}
        else
          File.write!(dest, String.trim_trailing(existing) <> "\n\n" <> block <> "\n")
          {:appended, dest}
        end
    end
  end

  defp extract_block(rendered) do
    [_, rest] = String.split(rendered, @start_marker, parts: 2)
    [inner, _] = String.split(rest, @end_marker, parts: 2)
    @start_marker <> inner <> @end_marker
  end

  defp replace_block(existing, block) do
    [before, rest] = String.split(existing, @start_marker, parts: 2)
    [_old, after_block] = String.split(rest, @end_marker, parts: 2)
    before <> block <> after_block
  end

  defp catalog_table do
    rows =
      LanternUI.Llms.catalog()
      |> Enum.flat_map(fn %{components: components} -> components end)
      |> Enum.map(fn %{name: name, doc: doc} -> "| `#{name}/1` | #{doc} |" end)
      |> Enum.join("\n")

    """
    ### Component catalog (generated — lantern_ui #{package_version()}, do not edit)

    | Component | Use when |
    |---|---|
    #{rows}

    """
  end

  defp package_version do
    :lantern_ui |> Application.spec(:vsn) |> to_string()
  rescue
    _ -> "dev"
  end

  defp package_root?(dir) do
    case File.read(Path.join(dir, "mix.exs")) do
      {:ok, contents} -> Regex.match?(~r/app:\s*:lantern_ui\b/, contents)
      _ -> false
    end
  end
end
