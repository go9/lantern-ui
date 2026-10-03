defmodule LanternUI.InstallSkillsTest do
  use ExUnit.Case, async: true

  alias LanternUI.InstallSkills

  setup do
    source = File.cwd!()
    target = Path.join(System.tmp_dir!(), "lantern-skills-#{System.unique_integer([:positive])}")
    File.mkdir_p!(target)
    on_exit(fn -> File.rm_rf!(target) end)
    {:ok, source: source, target: target}
  end

  test "copies skills and creates AGENTS.md with a live catalog", %{
    source: source,
    target: target
  } do
    report = InstallSkills.run(source, target)

    assert Enum.sort(report.skills.copied) == [
             "lantern-migration",
             "lantern-recipes",
             "lantern-ui-components",
             "phoenix-page-design"
           ]

    assert report.agents == :created

    agents = File.read!(Path.join(target, "AGENTS.md"))
    assert agents =~ "lantern-ui:rules:start"
    assert agents =~ "| `stat_card/1` |"
    assert agents =~ "| `toast_group/1` |"
    refute agents =~ "lantern-ui:catalog:start -->\n<!-- replaced"
    assert File.read!(Path.join(target, "skills/lantern-recipes/SKILL.md")) =~ "lantern-recipes"
  end

  test "re-run is idempotent; user edits outside the block survive", %{
    source: source,
    target: target
  } do
    InstallSkills.run(source, target)
    agents_path = Path.join(target, "AGENTS.md")
    File.write!(agents_path, "# My app\n\n" <> File.read!(agents_path))

    report = InstallSkills.run(source, target)

    assert report.skills.copied == []
    assert Enum.sort(report.skills.skipped) != []
    assert report.agents == :updated

    updated = File.read!(agents_path)
    assert updated =~ "# My app"
    assert updated =~ "| `stat_card/1` |"
    assert length(Regex.scan(~r/lantern-ui:rules:start/, updated)) == 1
  end

  test "changed skill files are skipped without --force, overwritten with it", %{
    source: source,
    target: target
  } do
    InstallSkills.run(source, target)
    skill = Path.join(target, "skills/lantern-recipes/SKILL.md")
    File.write!(skill, "user edit")

    skipped = InstallSkills.run(source, target)
    assert "lantern-recipes" in skipped.skills.skipped
    assert skipped.skills.overwritten == []
    assert File.read!(skill) == "user edit"

    forced = InstallSkills.run(source, target, force: true)
    assert forced.skills.overwritten == ["lantern-recipes"]
    assert File.read!(skill) =~ "lantern-recipes"
  end

  test "appends the block when AGENTS.md has no markers", %{source: source, target: target} do
    File.write!(Path.join(target, "AGENTS.md"), "# My app\n")
    report = InstallSkills.run(source, target)

    assert report.agents == :appended
    agents = File.read!(Path.join(target, "AGENTS.md"))
    assert agents =~ "# My app"
    assert agents =~ "lantern-ui:rules:start"
  end

  test "locate_source finds this package from its own tree" do
    assert {:ok, _} = InstallSkills.locate_source(File.cwd!())
  end
end
