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

  test "flags grouped-list markup", %{dir: dir} do
    File.write!(Path.join(dir, "page.ex"), """
    <.group_band title="Open">
    <GroupBand />
    <div class="group-band">x</div>
    """)

    rules = dir |> Lint.scan() |> Enum.map(& &1.rule) |> Enum.uniq()
    assert rules == [:group_band]
  end

  test "flags a hand-rolled table only without a lantern table", %{dir: dir} do
    File.write!(Path.join(dir, "hand.ex"), "<table><tr><td>x</td></tr></table>")

    File.write!(Path.join(dir, "lantern.ex"), """
    <.data_table id="t" rows={@rows}>
    <table><tr><td>legacy</td></tr></table>
    """)

    findings = Lint.scan(dir)
    assert [%{rule: :hand_table, path: "hand.ex"}] = findings
  end

  test "flags hand-rolled buttons, including multiline tags", %{dir: dir} do
    File.write!(Path.join(dir, "page.heex"), """
    <button>Save</button>
    <button
      type="button"
      phx-click="close"
    >×</button>
    """)

    findings = Lint.scan(dir)
    assert length(findings) == 2
    assert Enum.all?(findings, &(&1.rule == :hand_button))
    assert Enum.map(findings, & &1.line) == [1, 2]
  end

  test "flags deprecated components with their replacement", %{dir: dir} do
    File.write!(Path.join(dir, "page.heex"), """
    <.icon_button label="Delete" />
    <.segmented />
    """)

    findings = Lint.scan(dir)

    assert Enum.map(findings, &{&1.rule, &1.match}) == [
             {:deprecated_component, "<.icon_button"},
             {:deprecated_component, "<.segmented"}
           ]

    assert hd(findings).hint =~ "button"
    assert hd(findings).hint =~ "deprecated"
  end

  test "unknown components get did-you-mean from the eval confusables", %{dir: dir} do
    File.write!(Path.join(dir, "page.heex"), """
    <.stat label="Open" value={3} />
    <.toast message="hi" />
    """)

    findings = Lint.scan(dir)
    assert length(findings) == 2
    assert Enum.all?(findings, &(&1.rule == :unknown_component))
    assert hd(findings).hint =~ "stat_card"
    assert List.last(findings).hint =~ "toast_group"
  end

  test "unknown components get a generic did-you-mean; custom names stay silent", %{dir: dir} do
    File.write!(Path.join(dir, "page.heex"), """
    <.buton>Save</.buton>
    <.my_modal id="m" />
    <.form :let={f} for={@changeset} />
    """)

    findings = Lint.scan(dir)
    assert [%{rule: :unknown_component, match: "<.buton", hint: hint}] = findings
    assert hint =~ "<.button>"
  end

  test "names defined in the same file are local, not guesses", %{dir: dir} do
    File.write!(Path.join(dir, "helpers.ex"), """
    defp sep(assigns), do: ~H|<span />|
    def render(assigns), do: ~H|<.sep />|
    """)

    assert Lint.scan(dir) == []
  end

  describe "components the app defines in another file" do
    test "a sibling module's attr-declared component is not an unknown", %{dir: dir} do
      File.write!(Path.join(dir, "stat_bits.ex"), """
      defmodule MyApp.StatBits do
        attr :label, :string, required: true
        def stat(assigns), do: ~H|<span>{@label}</span>|
      end
      """)

      File.write!(Path.join(dir, "page.heex"), "<.stat label=\"Open\" />\n")

      assert Lint.scan(dir) == []
    end

    test "every def in a Phoenix.Component module counts, even without attrs", %{dir: dir} do
      File.write!(Path.join(dir, "core.ex"), """
      defmodule MyAppWeb.CoreComponents do
        use Phoenix.Component
        def buton(assigns), do: ~H|<span />|
      end
      """)

      File.write!(Path.join(dir, "page.heex"), "<.buton>Save</.buton>\n")

      assert Lint.scan(dir) == []
    end

    test "an app's `use MyAppWeb, :html` module counts too", %{dir: dir} do
      File.write!(Path.join(dir, "layouts.ex"), """
      defmodule MyAppWeb.Layouts do
        use MyAppWeb, :html
        def toast(assigns), do: ~H|<div />|
      end
      """)

      File.write!(Path.join(dir, "page.heex"), "<.toast message=\"hi\" />\n")

      assert Lint.scan(dir) == []
    end

    test "a plain module's undecorated def is not a component, so true unknowns still report", %{
      dir: dir
    } do
      File.write!(Path.join(dir, "util.ex"), """
      defmodule MyApp.Util do
        def stat(x), do: x
      end
      """)

      File.write!(
        Path.join(dir, "page.heex"),
        "<.stat label=\"Open\" />\n<.buton>Save</.buton>\n"
      )

      assert [%{match: "<.stat", hint: stat_hint}, %{match: "<.buton", hint: hint}] =
               Lint.scan(dir)

      assert stat_hint =~ "stat_card"
      assert hint =~ "<.button>"
    end

    test "a locally defined name does not hide a deprecated lantern component", %{dir: dir} do
      [%{component: deprecated} | _] = LanternUI.Deprecated.deprecated()

      File.write!(Path.join(dir, "core.ex"), """
      defmodule MyAppWeb.CoreComponents do
        use Phoenix.Component
        def #{deprecated}(assigns), do: ~H|<div />|
      end
      """)

      File.write!(Path.join(dir, "page.heex"), "<.#{deprecated} />\n")

      assert [%{rule: :deprecated_component}] = Lint.scan(dir)
    end

    test "lantern-lint:ignore and excluded dirs still behave", %{dir: dir} do
      File.mkdir_p!(Path.join(dir, "vendor"))

      File.write!(Path.join(dir, "vendor/core.ex"), """
      defmodule Vendor.Core do
        use Phoenix.Component
        def stat(assigns), do: ~H|<i />|
      end
      """)

      File.write!(Path.join(dir, ".lantern-lint.json"), ~s({"exclude": ["vendor/**"]}))

      File.write!(Path.join(dir, "page.heex"), """
      <.stat label="Open" />
      <%!-- lantern-lint:ignore --%>
      <.buton>Save</.buton>
      <.buton>Again</.buton>
      """)

      # vendor is excluded from linting but still defines `stat`; the ignore
      # comment covers only the line below it.
      assert [%{match: "<.buton", line: 4}] = Lint.scan(dir)
    end
  end

  test "unknown attrs on strict components get did-you-mean", %{dir: dir} do
    File.write!(Path.join(dir, "page.heex"), """
    <.stat_card lable="Open" value={3} />
    """)

    assert [
             %{
               rule: :unknown_attr,
               match: "lable",
               hint: hint
             }
           ] = Lint.scan(dir)

    assert hint =~ "label"
  end

  test "attrs pass through on components with :rest, and phx/data attrs are exempt", %{
    dir: dir
  } do
    File.write!(Path.join(dir, "page.heex"), """
    <.badge color="success" phx-click="x" data-part="y" class="z">Hi</.badge>
    <.stat_card
      label="Open"
      value={3}
      data-lantern-list-item
    />
    """)

    assert Lint.scan(dir) == []
  end

  test "allow_rules scopes one rule off matching files", %{dir: dir} do
    File.mkdir_p!(Path.join(dir, "lib/internal"))
    File.write!(Path.join(dir, "lib/internal/chrome.ex"), "<button>x</button>")
    File.write!(Path.join(dir, "lib/page.ex"), "<button>y</button>")

    File.write!(
      Path.join(dir, ".lantern-lint.json"),
      ~s|{"allow_rules": {"hand_button": ["lib/internal/**"]}}|
    )

    assert [%{path: "lib/page.ex", rule: :hand_button}] = Lint.scan(dir)
  end

  test "flags hand-rolled inputs, textareas, and selects; hidden inputs are exempt", %{dir: dir} do
    File.write!(Path.join(dir, "form.heex"), """
    <input type="text" name="q" />
    <input
      type="email"
    />
    <textarea name="body"></textarea>
    <select name="kind"></select>
    <input type="hidden" name="id" value="1" />
    <.input field={@form[:name]} />
    """)

    findings = Lint.scan(dir)

    assert Enum.map(findings, &{&1.rule, &1.line}) == [
             {:hand_input, 1},
             {:hand_input, 2},
             {:hand_input, 5},
             {:hand_input, 6}
           ]

    assert hd(findings).hint =~ "input/1"
  end

  test "hand_input allow_rules skip a component's own controls", %{dir: dir} do
    File.mkdir_p!(Path.join(dir, "lib/components"))
    File.write!(Path.join(dir, "lib/components/field.ex"), ~s|<input name="x" />|)
    File.write!(Path.join(dir, "lib/page.ex"), ~s|<input name="y" />|)

    File.write!(
      Path.join(dir, ".lantern-lint.json"),
      ~s|{"allow_rules": {"hand_input": ["lib/components/**"]}}|
    )

    assert [%{path: "lib/page.ex", rule: :hand_input}] = Lint.scan(dir)
  end

  test "a second <.page_shell> in one file is flagged on every occurrence", %{dir: dir} do
    File.write!(Path.join(dir, "one.heex"), ~s|<.page_shell id="a" title="A" />\n|)

    File.write!(Path.join(dir, "two.heex"), """
    <.page_shell id="b" title="B" />
    <.page_shell id="c" title="C" />
    """)

    findings = Enum.filter(Lint.scan(dir), &(&1.rule == :single_page_shell))

    assert Enum.map(findings, &{&1.path, &1.line}) == [{"two.heex", 1}, {"two.heex", 2}]
    assert hd(findings).hint =~ "one <.page_shell>"
  end

  test "hand_input reads the whole tag: a `>` inside braces does not hide type=hidden", %{
    dir: dir
  } do
    File.write!(Path.join(dir, "form.heex"), """
    <input value={@a |> String.trim()} type="hidden" name="x" />
    <input type={"hidden"} value={@b} />
    <input value={@c |> String.trim()} name="visible" />
    """)

    assert [%{rule: :hand_input, line: 3}] =
             Enum.filter(Lint.scan(dir), &(&1.rule == :hand_input))
  end

  test "single_page_shell: shells in separate function clauses or case arms are alternatives", %{
    dir: dir
  } do
    File.write!(Path.join(dir, "live.ex"), """
    defmodule MyAppWeb.Live do
      def render(%{live_action: :index} = assigns) do
        ~H\"\"\"
        <.page_shell id="a" title="A" />
        \"\"\"
      end

      def render(assigns) do
        ~H\"\"\"
        <.page_shell id="b" title="B" />
        \"\"\"
      end
    end
    """)

    File.write!(Path.join(dir, "case.heex"), """
    <%= case @live_action do %>
      <% :index -> %>
        <.page_shell id="c" title="C" />
      <% :edit -> %>
        <.page_shell id="d" title="D" />
    <% end %>
    """)

    File.write!(Path.join(dir, "conditional.heex"), """
    <.page_shell :if={@a} id="e" title="E" />
    <.page_shell :if={!@a} id="f" title="F" />
    """)

    assert Enum.filter(Lint.scan(dir), &(&1.rule == :single_page_shell)) == []
  end

  test "single_page_shell: two shells in one template are flagged; allow_rules skips them", %{
    dir: dir
  } do
    File.mkdir_p!(Path.join(dir, "lib/legacy"))

    File.write!(
      Path.join(dir, "lib/legacy/two.heex"),
      ~s|<.page_shell id="a" title="A" />\n<.page_shell id="b" title="B" />\n|
    )

    assert length(Enum.filter(Lint.scan(dir), &(&1.rule == :single_page_shell))) == 2

    File.write!(
      Path.join(dir, ".lantern-lint.json"),
      ~s|{"allow_rules": {"single_page_shell": ["lib/legacy/**"]}}|
    )

    assert Enum.filter(Lint.scan(dir), &(&1.rule == :single_page_shell)) == []
  end

  test "page_header is deprecated in favour of page_shell", %{dir: dir} do
    File.write!(Path.join(dir, "page.heex"), ~s|<.page_header title="Tickets" />\n|)

    assert [%{rule: :deprecated_component, match: "<.page_header"} = finding] = Lint.scan(dir)
    assert finding.hint =~ "<.page_shell>"
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
