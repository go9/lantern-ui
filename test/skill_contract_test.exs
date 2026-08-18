defmodule LanternUI.SkillContractTest do
  use ExUnit.Case, async: true

  @skills ~w(lantern-ui-components lantern-migration phoenix-page-design)

  test "public skills have canonical frontmatter and no private portfolio paths" do
    Enum.each(@skills, fn name ->
      body = File.read!(Path.expand("../skills/#{name}/SKILL.md", __DIR__))

      assert body =~ "name: #{name}"
      assert body =~ "license: MIT"
      assert body =~ "source: https://github.com/go9/lantern-ui"
      refute body =~ "~/Sites/"
      refute body =~ "/Users/"
      refute body =~ "orlando-umbrella"
      refute body =~ "enventory_new"
      refute body =~ "Flicker project"
    end)
  end
end
