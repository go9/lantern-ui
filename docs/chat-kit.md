# Chat Kit

Chat Kit is present on the main branch, which currently targets LanternUI 0.7.0.
Hex 0.7 is not published yet. Install the reproducible git revision below until
that release is available:

```elixir
{:lantern_ui, git: "https://github.com/go9/lantern-ui.git", ref: "0ad0627054ee6765c81eceace58ad316959565bb"}
```

Chat Kit is a composed model for conversations. `Avatar`, `Message`, and
`MessageScroller` are designed to work together: avatars provide identity,
messages provide visual alignment and tone, and the scroller provides the
follow-aware transcript viewport. The host LiveView owns the messages, state,
events, and content.

## Composed example

In a LiveView that uses `LanternUI`, render the conversation from host-owned
assigns. This example expects `@messages` to contain maps with `:id`, `:role`,
and `:content` keys, and `@streaming` to be a boolean:

```heex
<.message_scroller id="conversation" label="Conversation" follow={true} busy={@streaming}>
  <.message_scroller_item
    :for={message <- @messages}
    id={"message-#{message.id}"}
    message_id={to_string(message.id)}
    scroll_anchor={message.role == :assistant}
  >
    <.message
      align={if message.role == :user, do: "end", else: "start"}
      tone={if message.role == :user, do: "primary", else: "surface"}
    >
      <:avatar>
        <.avatar initials={if message.role == :user, do: "You", else: "AI"} />
      </:avatar>
      <:header>{if message.role == :user, do: "You", else: "Assistant"}</:header>
      {message.content}
      <:footer :if={message.role == :assistant}>Assistant response</:footer>
    </.message>
  </.message_scroller_item>

  <.message_scroller_item :if={@streaming} id="streaming-message" message_id="streaming">
    <.message align="start" tone="surface">
      <:avatar><.avatar initials="AI" /></:avatar>
      <:header>Assistant</:header>
      <span aria-label="Assistant is responding">...</span>
      <:footer>Streaming</:footer>
    </.message>
  </.message_scroller_item>
</.message_scroller>
```

The host can replace the text content with rendered markdown or other content.
It should also assign stable item ids and update the message content as the
conversation changes.

## Following the latest message

`follow={true}` starts the viewport at the bottom and follows new content only
while the user remains at the bottom. Scrolling away pauses follow. The
Jump to latest control then becomes keyboard reachable; clicking it resumes
follow and returns to the latest content.

Mark an item with `scroll_anchor={true}` when a newly appended turn should be
positioned with context still visible above it. The `peek` value controls that
position. For example:

```heex
<.message_scroller_item id="assistant-turn" scroll_anchor={true}>
  <.message>Here is the next turn.</.message>
</.message_scroller_item>
```

## Streaming

The scroller hook observes streamed token patches as well as appended message
nodes. The host should update message content through normal LiveView assigns or
streams, not issue manual JavaScript scroll commands. Set `busy={true}` while a
response is being produced; `busy` maps to `aria-busy="true"` on the transcript
log.

## Accessibility

The scroller renders a labelled region containing a log with `aria-live="polite"`
and `aria-relevant="additions"`. The host remains responsible for semantic
message author labelling, including making the relationship between an author
and its message clear to assistive technology. The example's `header` slot is
visual metadata and is not a substitute for host-owned author semantics.

The jump-to-latest button is keyboard reachable when the user is away from the
bottom. Reduced-motion preferences are respected by the hook when returning to
the latest content.

## Theming and imports

Import both `lantern_ui_theme.css` and `lantern_ui.css` for the default theme:

```css
@import "../../deps/lantern_ui/priv/static/lantern_ui_theme.css";
@import "../../deps/lantern_ui/priv/static/lantern_ui.css";
```

The Chat Kit-specific tokens are:

- `--lantern-chat-avatar-xs`
- `--lantern-chat-message-max-width`
- `--lantern-chat-scroller-padding-bottom`
- `--lantern-chat-item-intrinsic-height`
- `--lantern-chat-button-offset`
- `--lantern-chat-button-visibility-duration`

Chat Kit also consumes these shared tokens:

- `--lantern-surface-raised`
- `--lantern-fg`
- `--lantern-fg-muted`
- `--lantern-fg-subtle`
- `--lantern-border`
- `--lantern-primary`
- `--lantern-primary-fg`
- `--lantern-radius`
- `--lantern-radius-sm`
- `--lantern-space-xs`
- `--lantern-space-sm`
- `--lantern-space-md`
- `--lantern-shadow`
- `--lantern-duration`
- `--lantern-ease`

Importing `lantern_ui_theme.css` supplies all of these tokens. A host theme
that imports only `lantern_ui.css` must define every token listed above.
