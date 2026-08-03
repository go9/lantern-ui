// Whole-bundle invariants that no per-hook test can see.

import assert from "node:assert/strict"
import { readFile } from "node:fs/promises"
import test from "node:test"

import { hooks } from "./helpers/dom.mjs"

const source = await readFile(new URL("../../priv/static/lantern_ui_hooks.js", import.meta.url), "utf8")

test("no hook defines the same method twice", () => {
  // A duplicated key in an object literal is not an error in JavaScript: the
  // last definition silently wins and the earlier one becomes unreachable. That
  // shipped in `LanternCommand`, where a second `push` shadowed the
  // `pushEvent`/`pushEventTo` router — killing LiveComponent support and making
  // the survivor recurse into itself on every keystroke. Nothing warned: not
  // `node --check`, not the compiler, not any render-level test.
  const duplicates = []
  let hook = null
  let seen = null

  source.split("\n").forEach((line, index) => {
    const start = line.match(/^const (\w+) = \{$/)
    if (start) {
      hook = start[1]
      seen = new Map()
      return
    }
    if (line === "}") {
      hook = null
      return
    }
    if (!hook) return

    const method = line.match(/^ {2}([A-Za-z_$][\w$]*)\(/)
    if (!method) return
    const name = method[1]
    if (seen.has(name)) {
      duplicates.push(`${hook}.${name} — lines ${seen.get(name)} and ${index + 1}`)
    } else {
      seen.set(name, index + 1)
    }
  })

  assert.deepEqual(duplicates, [])
})

test("every hook in the Hooks map is also a named export", () => {
  // A hook missing from either surface is a silent no-op for whichever import
  // style the consumer chose.
  for (const name of Object.keys(hooks.default)) {
    assert.equal(hooks[name], hooks.default[name], `${name} is not exported by name`)
  }
})
