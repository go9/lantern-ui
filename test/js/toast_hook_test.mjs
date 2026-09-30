import assert from "node:assert/strict"
import { afterEach, test } from "node:test"
import { hooks, mountHook } from "./helpers/dom.mjs"

const mounts = []
const realNow = Date.now
function mount(markup = '<div id="toasts" data-max="3" phx-hook="LanternToast" aria-live="polite"><div data-part="flashes" class="lui-toast-layer"></div><div id="toasts-client" data-part="client" class="lui-toast-layer" phx-update="ignore"></div></div>') {
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
  const flashes = el.querySelector('[data-part="flashes"]')
  flashes.innerHTML = `
    <div class="lui-toast" data-kind="info" data-flash-key="info">
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

test("client toasts survive LiveView updates while flash cards remain server-owned", () => {
  const { hook, el, window } = mount()
  hook.add({ message: "Survives a patch", duration: 0 })
  const clientToast = el.querySelector('[data-part="client"] .lui-toast')
  const flashes = el.querySelector('[data-part="flashes"]')

  // Simulate morphdom updating the server-owned flash layer. The ignored client
  // child remains intact, then hook.updated() reconciles the shared deck.
  flashes.innerHTML = `
    <div class="lui-toast" data-kind="error" data-flash-key="error">
      <div class="lui-toast-header"><strong class="lui-toast-title">Error</strong>
        <button data-part="close" aria-label="Close" phx-click="lv:clear-flash" phx-value-key="error">×</button></div>
      <div class="lui-toast-body"><p class="lui-toast-message">Invalid value</p></div>
    </div>`
  hook.updated()

  assert.equal(clientToast.isConnected, true)
  assert.equal(clientToast.querySelector(".lui-toast-message").textContent, "Survives a patch")
  const flashToast = flashes.querySelector(".lui-toast")
  assert.equal(flashToast.style.getPropertyValue("--toast-index"), "0")
  assert.equal(clientToast.style.getPropertyValue("--toast-index"), "1")
  const clear = flashToast.querySelector('[data-part="close"]')
  assert.equal(clear.getAttribute("phx-click"), "lv:clear-flash")
  clear.dispatchEvent(new window.MouseEvent("click", { bubbles: true }))
  assert.equal(flashToast.isConnected, true, "the LiveView handles the flash clear event")

  flashes.innerHTML = ""
  hook.updated()
  assert.equal(clientToast.isConnected, true)
  assert.equal(flashes.querySelector(".lui-toast"), null)
})

test("only nonnegative integer durations are accepted; invalid values default to 4000ms", () => {
  const { hook, el } = mount()
  for (const duration of [false, null, 1.5, "0", -1]) {
    hook.add({ message: String(duration), duration })
    const toast = el.querySelector('[data-part="client"] .lui-toast')
    assert.equal(hook.toastTimers.get(toast).remaining, 4000)
    assert.equal(toast.style.getPropertyValue("--duration"), "4000ms")
    hook.remove(toast)
    toast.remove()
    hook.toastTimers.delete(toast)
  }

  hook.add({ message: "sticky", duration: 0 })
  const sticky = el.querySelector('[data-part="client"] .lui-toast')
  assert.equal(hook.toastTimers.has(sticky), false)
  assert.equal(sticky.style.getPropertyValue("--duration"), "0ms")
})
