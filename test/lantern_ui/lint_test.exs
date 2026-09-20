defmodule LanternUI.LintTest do
  use ExUnit.Case, async: true

  alias LanternUI.Lint

  setup do
    dir = Path.join(System.tmp_dir!(), "lantern-lint-#{System.unique_integer([:positive])}")
    File.mkdir_p!(dir)
    on_exit(fn -> File.rm_rf!(dir) end)
    {:ok, dir: dir}
  end

  test "flags text-[Npx], pixel boxes, palette colors, and hex greys", %{dir: dir} do
    File.write!(Path.join(dir, "page.ex"), """
    ~H\"\"\"
    <span class="font-mono text-[11px] text-gray-500">#12</span>
    <div class="w-[220px] h-[32px] bg-red-500 text-[#71717a]">x</div>
    \"\"\"
    """)

    rules = dir |> Lint.scan() |> Enum.map(&{&1.rule, &1.match}) |> MapSet.new()

    assert MapSet.member?(rules, {:arbitrary_text_size, "text-[11px]"})
    assert MapSet.member?(rules, {:arbitrary_box, "w-[220px]"})
    assert MapSet.member?(rules, {:arbitrary_box, "h-[32px]"})
    assert MapSet.member?(rules, {:palette_color, "text-gray-500"})
    assert MapSet.member?(rules, {:palette_color, "bg-red-500"})
    assert MapSet.member?(rules, {:hex_color, "text-[#71717a]"})
  end

  test "allows semantic grey roles and named sizes", %{dir: dir} do
    File.write!(Path.join(dir, "ok.heex"), """
    <span class="text-meta text-foreground-softest">3m</span>
    <span class="text-caption text-foreground-soft">label</span>
    <span class="text-mono-meta text-foreground">#12</span>
    <span class="text-muted-foreground">disabled</span>
    <span class="text-foreground-softer">deprecated alias, still legal</span>
    <span class="text-xs text-danger bg-success">ok</span>
    """)

    assert Lint.scan(dir) == []
  end

  test "lantern-lint:ignore skips the marked line", %{dir: dir} do
    File.write!(Path.join(dir, "ignored.ex"), """
    # lantern-lint:ignore
    ~H[<span class="text-[11px]">kept</span>]
    ~H[<span class="text-[11px]">flagged</span>]
    """)

    [finding] = Lint.scan(dir)
    assert finding.line == 3
  end

  test ".lantern-lint.json allow globs skip a file", %{dir: dir} do
    File.mkdir_p!(Path.join(dir, "lib/vendor"))
    File.write!(Path.join(dir, "lib/vendor/old.ex"), ~s|class="text-[11px] bg-red-500"|)
    File.write!(Path.join(dir, "lib/page.ex"), ~s|class="text-[11px]"|)

    File.write!(
      Path.join(dir, ".lantern-lint.json"),
      ~s|{"allow": ["lib/vendor/**"]}|
    )

    [finding] = Lint.scan(dir)
    assert finding.path == "lib/page.ex"
  end

  test "skips deps and _build directories", %{dir: dir} do
    File.mkdir_p!(Path.join(dir, "deps/foo"))
    File.write!(Path.join(dir, "deps/foo/x.ex"), ~s|class="text-[11px]"|)
    File.write!(Path.join(dir, "app.ex"), ~s|class="text-meta"|)

    assert Lint.scan(dir) == []
  end

  test "11px hint names text-meta", %{dir: dir} do
    File.write!(Path.join(dir, "a.ex"), ~s|class="text-[11px]"|)
    [finding] = Lint.scan(dir)
    assert finding.hint =~ "text-meta"
  end

  test "ships named type utilities and tokens" do
    css = File.read!(Path.expand("../../priv/static/lantern_ui.css", __DIR__))
    theme = File.read!(Path.expand("../../priv/static/lantern_ui_theme.css", __DIR__))
    compat = File.read!(Path.expand("../../priv/static/lantern_ui_compat.css", __DIR__))

    assert css =~ ".text-meta"
    assert css =~ ".text-caption"
    assert css =~ ".text-mono-meta"
    assert theme =~ "--lantern-text-meta: 11px"
    assert theme =~ "--lantern-text-caption: 12px"
    assert compat =~ "--text-color-muted-foreground"
    assert compat =~ "--foreground-softer: var(--foreground-soft)"
  end
end
