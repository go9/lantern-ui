import assert from "node:assert/strict"
import { afterEach, test } from "node:test"
import { hooks, mountHook } from "./helpers/dom.mjs"

const mounts = []
const realNow = Date.now
function mount(markup = '<div id="toasts" data-max="3" phx-hook="LanternToast" aria-live="polite"></div>') {
  const context = mountHook(hooks.LanternToast, markup, { rootId: "toasts" })
  mounts.push(context)
  return context
}

afterEach(() => {
  Date.now = realNow
  mounts.splice(0).forEach((context) => context.unmount())
})

test("new toasts are first in the deck and old items are removed past the hard cap", () => {
  const { hook, el } = mount()
  for (let i = 1; i <= 11; i++) hook.add({ message: `toast ${i}`, duration: 0 })

  const cards = [...el.querySelectorAll(".lui-toast")]
  assert.equal(cards.length, 10)
  assert.equal(cards[0].querySelector(".lui-toast-message").textContent, "toast 11")
  assert.equal(cards.at(-1).querySelector(".lui-toast-message").textContent, "toast 2")
  assert.equal(cards[0].dataset.stackHidden, "false")
  assert.equal(cards[2].dataset.stackHidden, "false")
  assert.equal(cards[3].dataset.stackHidden, "true")
})

test("hover expands the stack and pauses then resumes the remaining timer", () => {
  const { hook, el, window } = mount()
  hook.add({ message: "temporary", duration: 1000 })
  const toast = el.querySelector(".lui-toast")
  const timer = hook.toastTimers.get(toast)
  const start = Date.now()
  Date.now = () => start + 250
  el.dispatchEvent(new window.Event("pointerenter"))

  assert.equal(el.dataset.expanded, "true")
  assert.equal(el.dataset.paused, "true")
  assert.ok(timer.remaining <= 750 && timer.remaining > 700)
  assert.equal(timer.timer, null)

  el.dispatchEvent(new window.Event("pointerleave"))
  assert.equal(el.dataset.expanded, "false")
  assert.ok(timer.timer)
})

test("an action pushes its LiveView event and dismisses the toast", () => {
  const { hook, el, pushEvent, window } = mount()
  hook.add({ message: "Saved", duration: 0, action: { label: "Undo", event: "undo_save" } })
  const toast = el.querySelector(".lui-toast")
  const button = toast.querySelector('[data-part="action"]')
  assert.equal(button.dataset.size, "sm")
  button.dispatchEvent(new window.MouseEvent("click", { bubbles: true }))

  assert.deepEqual(pushEvent, [{ event: "undo_save", payload: {} }])
  assert.ok(toast.classList.contains("lui-toast-out"))
})

test("server-rendered flash cards mount as sticky toasts", () => {
  const { hook, el } = mount()
  el.innerHTML = `
    <div class="lui-toast" data-kind="info" data-flash-key="info" data-duration="0">
      <div class="lui-toast-header"><strong class="lui-toast-title">Notice</strong>
        <button data-part="close" aria-label="Close">×</button></div>
      <div class="lui-toast-body"><p class="lui-toast-message">Saved</p></div>
    </div>`
  hook.updated()
  const flash = el.querySelector(".lui-toast")

  assert.equal(hook.toastTimers.has(flash), false)
  assert.equal(flash.querySelector(".lui-toast-title").textContent, "Notice")
  assert.equal(flash.querySelector(".lui-toast-message").textContent, "Saved")
  assert.equal(flash.querySelector(".lui-toast-progress"), null)
})
