# Database-Backed Broadcast Chat Design

## Goal

Replace the template counter page with a usable public chat lobby. Visitors choose a temporary nickname stored in the Rails session, send messages that persist in PostgreSQL, and receive messages from other visitors in real time through Phlex Reactive and pgbus.

## Scope

The first version has one public room named `lobby`, session-backed temporary identities, and an initial history of the most recent 50 messages. It does not include accounts, private messages, multiple rooms, presence counts, attachments, editing, deletion, or history pagination.

## Architecture

The implementation follows the phlex-reactive cross-tab chat pattern already supported by the repository:

- `ChatMessage` persists the room, author, body, and timestamps. It owns validation, the deterministic recent-history query, and the raw stream key parts `['chat', room]`.
- `Components::Chat::Room` includes `Phlex::Rails::Helpers::TurboStreamFrom`, subscribes with `turbo_stream_from(*ChatMessage.stream_key('lobby'))`, and renders the header, message list, and composer.
- `Components::Chat::Message` renders one persisted message. It includes `Phlex::Reactive::Streamable`, accepts `chat_message:` in its initializer, declares `self.model_param_name = :chat_message`, and returns `dom_id(@chat_message)` from `id`. These interfaces allow record-valued append streams to rebuild and target the component.
- `Components::Chat::Composer` is a reactive component. Its `send_message` action validates input, creates the record, and broadcasts a rendered message append in the same transaction.
- A small nickname controller writes a normalized nickname to the Rails session and redirects to the lobby. Once set, the nickname remains fixed for that session.
- `PagesController#home` loads the most recent 50 lobby records and either renders the nickname gate or the chat room.

The application will configure Phlex Reactive to inherit from `ApplicationController` so reactive actions have the same session and CSRF context as normal requests. `Components::Chat::Composer` deliberately declares `skip_verify_authorized :send_message`: the lobby is a public anonymous resource, while the gem's default authorization guard remains enabled for every component that does not explicitly opt out.

## Data Model

Create `chat_messages` with:

| Column | Type | Constraints |
| --- | --- | --- |
| `room` | string | non-null, default `lobby` |
| `author` | string | non-null, 2-20 characters after trimming |
| `body` | text | non-null, 1-500 characters after trimming |
| timestamps | datetime | non-null Rails timestamps |

Add an index on `[room, created_at, id]`. `ChatMessage.recent_for('lobby', limit: 50)` selects by `(created_at DESC, id DESC)`, limits to 50, and returns those records by `(created_at ASC, id ASC)` for display. The id is the deterministic tie-breaker when records share a timestamp.

The stream key method returns raw parts, not a prejoined string, so subscription and broadcast use the same pgbus-safe key construction.

## Identity Flow

On a first visit, a visitor sees a compact nickname form instead of the lobby. Submitting a valid nickname stores only the normalized string in `session[:chat_nickname]`. An invalid nickname redisplays the gate with an inline error. Later identity submissions do not overwrite an existing session nickname, so one visitor cannot appear under multiple names during the same session.

The composer receives the nickname from server-side session context when rendered. The action ignores author and room parameters and persists the signed display label and room originally rendered by the server. Nicknames are unauthenticated and non-unique; they are display labels, not proof of identity. Because the nickname is immutable for the session, existing and newly rendered composer tokens use the same author label.

## Message Flow

1. The browser submits `body` to `Components::Chat::Composer#send_message` through the Phlex Reactive action endpoint.
2. The action builds a `ChatMessage` for `lobby` using the signed author state and normalized body, then validates it before saving.
3. In the same transaction, `Components::Chat::Message.broadcast_to(*ChatMessage.stream_key('lobby'), append: message, target: container_id, exclude: reactive_connection_id)` sends the persisted record to peers.
4. Other subscribed sessions receive that append over pgbus SSE. The actor response explicitly returns `reply.replace.stream(Components::Chat::Message.append(target: container_id, model: message))`: replacing the composer clears its successful input, and the companion stream appends the actor's copy. Excluding the actor from the broadcast ensures each client gets one append through exactly one lane.
5. Reloading the page queries PostgreSQL and reconstructs the latest 50 messages.

If validation fails, the composer retains the normalized body and error messages in reactive render state, returns `reply.replace`, and neither saves nor broadcasts. A database or broadcast exception rolls back the transaction. The application configures `Phlex::Reactive.error_flash` and renders the gem's flash target in the layout so unexpected failures show a concise retry message; validation errors remain inline beside the input.

## Interface

The page is a focused, single-column chat surface rather than a marketing page. A restrained header shows `公共大厅`, a real-time broadcast label, and the current nickname as static identity text. The main region is a scrollable chronological message list. Every broadcast uses viewer-independent markup: messages share one consistent alignment and neutral bubble treatment with author initials, names, and timestamps. The server does not attempt recipient-specific styling because one rendered append is fanned out unchanged to every subscriber.

The composer stays at the bottom of the chat surface and contains a message field plus an icon send button with an accessible label and tooltip. Enter submits. Successful submission clears the field. The layout uses stable dimensions and responsive constraints so it remains readable without overlap on desktop and mobile.

The header does not display an online-user count or claim transport health that the app does not measure. The real-time label describes the delivery mode only.

## Validation And Security

- Nicknames are stripped and limited to 2-20 characters.
- Message bodies are stripped and limited to 1-500 characters.
- Empty or invalid values render inline feedback and do not write to the database.
- The action accepts only `body`; room and author come from signed server state.
- Phlex text rendering escapes nickname and message content to prevent stored HTML execution.
- The reactive action uses the application controller session and CSRF context.
- `skip_verify_authorized :send_message` is scoped to this public action; the global fail-closed authorization guard remains enabled.

## Testing

Focused automated coverage will include:

- Model tests for normalization, validation, recent-50 ordering with an id tie-breaker, and stream keys.
- Request/controller tests for setting, changing, and rejecting nicknames in the session.
- Component/action tests for record creation, inline validation, actor reply append, peer broadcast append, lobby targeting, and sender connection exclusion.
- Rendering tests for the nickname gate, persisted history, viewer-independent message markup, and message escaping.
- An end-to-end multi-session check using two isolated browser contexts. Both wait for their pgbus stream sources, one sends a unique body, and each must contain exactly one matching message node within a fixed timeout. Reloading then confirms the same single persisted message is reconstructed from PostgreSQL.

Before completion, run the Rails test suite, RuboCop, and Brakeman. At 1440x900 and 390x844 browser viewports, assert that the message list and composer are visible and that the document has no horizontal overflow; retain screenshots as supporting visual evidence.

## Acceptance Criteria

- A visitor must set a valid temporary nickname before viewing or sending in the lobby.
- A nickname cannot be changed after it is set for the current session.
- Two independent browser sessions with different nicknames can send messages to each other without refreshing.
- Each message appears exactly once for its sender and once for every other connected subscriber.
- Messages survive refresh because the page reconstructs history from PostgreSQL rather than in-memory component state.
- A new page load renders at most the most recent 50 messages in chronological order.
- Blank or oversized messages and invalid nicknames are rejected with visible feedback.
- At 1440x900 and 390x844, the message list and composer remain visible with no horizontal overflow.
