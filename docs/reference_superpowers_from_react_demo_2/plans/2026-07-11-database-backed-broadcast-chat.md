# Database-Backed Broadcast Chat Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a single-room Rails chat where session-named visitors persist messages in PostgreSQL and receive each other's messages through Phlex Reactive and pgbus SSE.

**Architecture:** A normalized `ChatMessage` model owns deterministic recent-history and stream keys. A normal Rails controller owns the temporary nickname session, while Phlex `Room`, `Message`, and reactive `Composer` components own subscription, rendering, actor replies, and peer broadcasts. The sender gets an explicit append in the reactive HTTP response and is excluded from the peer broadcast.

**Tech Stack:** Rails 8.1, PostgreSQL, Minitest, Phlex Rails, phlex-reactive 0.12.1, pgbus SSE, Turbo Streams, Tailwind CSS, DaisyUI

---

## File Map

- Create `db/migrate/*_create_chat_messages.rb`: persisted lobby message schema and compound index.
- Create `app/models/chat_message.rb`: normalization, validation, recent-history query, and raw stream key.
- Create `app/controllers/chat_identities_controller.rb`: validate and write `session[:chat_nickname]`.
- Create `app/forms/chat_identity.rb`: normalized, non-persisted nickname validation.
- Create `app/components/chat/message.rb`: stable, viewer-independent record rendering and append stream payload.
- Create `app/components/chat/composer.rb`: public reactive send action, inline validation state, actor append, and peer broadcast.
- Create `app/components/chat/room.rb`: pgbus subscription, header, history container, and composer.
- Create `app/components/chat/nickname_gate.rb`: first-visit nickname form.
- Modify `app/views/pages/home.rb`: choose the gate or lobby and supply recent history.
- Modify `app/controllers/pages_controller.rb`: expose the normalized session nickname and query lobby history.
- Modify `config/routes.rb`: nickname update route.
- Modify `config/initializers/phlex_reactive.rb`: application controller inheritance, renderer, and unexpected-error flash.
- Modify `app/views/layouts/application.html.erb`: full-height application shell and flash target.
- Modify `app/assets/tailwind/application.css`: chat surface sizing, scrolling, focus, and responsive constraints.
- Create focused model, controller, component, and integration tests under `test/`.
- Create `test/application_system_test_case.rb` and `test/system/chat_test.rb`: reproducible two-session and responsive browser checks.

### Task 1: Persisted Message Contract

**Files:**
- Create: `db/migrate/*_create_chat_messages.rb`
- Create: `app/models/chat_message.rb`
- Create: `test/models/chat_message_test.rb`

- [ ] **Step 1: Record the dirty-worktree baseline**

Save `git diff --binary -- Procfile.dev app/components/counter.rb bin/setup` and SHA-256 hashes of those three files under `/tmp/react-demo-chat-baseline/`. Every commit in this plan must use an explicit path-limited `git add`; never use `git add .` or `git commit -a`.

- [ ] **Step 2: Write failing model tests**

Cover stripped author/body values, nickname length 2-20, body length 1-500, `stream_key('lobby') == ['chat', 'lobby']`, and `recent_for` returning the newest 50 in `(created_at, id)` ascending display order.

- [ ] **Step 3: Verify red**

Run: `bin/rails test test/models/chat_message_test.rb`
Expected: failure because `ChatMessage` and its table do not exist.

- [ ] **Step 4: Add the migration and minimal model**

Use `before_validation` normalization, explicit length/presence validations, a class method returning raw stream key parts, and a two-stage recent query: descending limit followed by ascending Ruby/SQL order without losing the 50-record cap. Add index `%i[room created_at id]`.

- [ ] **Step 5: Migrate and verify green**

Run: `bin/rails db:migrate && bin/rails test test/models/chat_message_test.rb`
Expected: all model tests pass.

- [ ] **Step 6: Commit the model slice**

Commit only the migration, schema, model, and model test.

### Task 2: Session Nickname Flow

**Files:**
- Create: `app/forms/chat_identity.rb`
- Create: `app/controllers/chat_identities_controller.rb`
- Create: `app/components/chat/nickname_gate.rb`
- Create: `test/controllers/chat_identities_controller_test.rb`
- Modify: `config/routes.rb`
- Modify: `app/controllers/pages_controller.rb`
- Modify: `app/views/pages/home.rb`

- [ ] **Step 1: Write failing request tests**

Test that `PATCH /chat/identity` strips and stores a valid nickname, redirects home, rejects blank/short/overlong values by rendering the nickname gate at status 422 with inline feedback, and replaces an existing session nickname. An invalid change must leave an existing valid session nickname unchanged. The fresh composer identity assertion belongs to Task 4, after Composer and Room exist.

- [ ] **Step 2: Verify red**

Run: `bin/rails test test/controllers/chat_identities_controller_test.rb`
Expected: route/controller failures.

- [ ] **Step 3: Implement the controller and route**

Validate through a small `ChatIdentity` ActiveModel form object without persisting a user. Store only the normalized nickname in session. On invalid PATCH, render `Views::Pages::Home` with the invalid form and status 422 without mutating the session. Make `PagesController#home` pass `nickname:` and, only when present, `ChatMessage.recent_for('lobby')` to the page view. Implement the minimal `NicknameGate` and Home gate branch in this task so the 422 contract is real.

- [ ] **Step 4: Verify green**

Run: `bin/rails test test/controllers/chat_identities_controller_test.rb`
Expected: controller tests pass.

- [ ] **Step 5: Commit the identity slice**

Path-limit staging to `config/routes.rb`, `app/forms/chat_identity.rb`, `app/controllers/chat_identities_controller.rb`, `app/controllers/pages_controller.rb`, `app/components/chat/nickname_gate.rb`, `app/views/pages/home.rb`, and `test/controllers/chat_identities_controller_test.rb`, then commit that slice.

### Task 3: Message Rendering

**Files:**
- Create: `app/components/chat/message.rb`
- Create: `test/components/chat/message_test.rb`

- [ ] **Step 1: Write failing component rendering tests**

Assert that a message's rendered root and `#id` both equal `chat_message_ID`, content escapes author/body text, time uses semantic markup, and classes are viewer-independent.

- [ ] **Step 2: Verify red**

Run: `bin/rails test test/components/chat/message_test.rb`
Expected: missing component constants.

- [ ] **Step 3: Implement minimal components**

`Message` includes `Phlex::Reactive::Streamable` and `Phlex::Rails::Helpers::DOMID`, defines `initialize(chat_message:)`, `.model_param_name`, and `id = dom_id(@chat_message)`, and renders `id:` on its root.

- [ ] **Step 4: Verify green**

Run: `bin/rails test test/components/chat/message_test.rb`.
Expected: message rendering tests pass.

- [ ] **Step 5: Commit the rendering slice**

Commit only the message component and its test.

### Task 4: Reactive Composer And Two-Lane Delivery

**Files:**
- Create: `app/components/chat/composer.rb`
- Create: `app/components/chat/room.rb`
- Create: `test/components/chat/composer_test.rb`
- Create: `test/components/chat/room_test.rb`
- Modify: `test/test_helper.rb`
- Modify: `config/initializers/phlex_reactive.rb`
- Modify: `app/views/layouts/application.html.erb`

- [ ] **Step 1: Add test helpers and write failing action tests**

Include `Phlex::Reactive::TestHelpers`. Wrap `run_reactive` in `Phlex::Reactive.with_connection_id('actor-connection')`, capture/stub `Components::Chat::Message.broadcast_to`, and assert exact positional keys `('chat', 'lobby')` plus `append: persisted_message`, `target: 'chat-messages-lobby'`, and `exclude: 'actor-connection'`. Inspect `result.streams` for exactly one composer replace and one actor append targeting the same container. Assert blank and overlong bodies render inline errors, retain normalized input, create nothing, and never call broadcast. Assert undeclared author/room params cannot override signed state.

Add an HTTP/token lifecycle test: mint an old composer token, PATCH the session nickname, invoke the old token through `post_reactive_action`, and confirm it persists the old signed author. A fresh GET must render a composer token/state for the new author. This pins the approved anonymous stale-token semantics and exercises the configured ApplicationController boundary.

- [ ] **Step 2: Verify red**

Run: `bin/rails test test/components/chat/composer_test.rb`
Expected: missing composer and action contract.

- [ ] **Step 3: Implement the reactive composer**

Declare `reactive_state :room, :author, :body, :errors`, `action :send_message, params: { body: :string }`, and `skip_verify_authorized :send_message`. Define stable `id = "chat-composer-#{@room}"` and render that id through `reactive_root`. Build/validate before save. On failure return `reply.replace`; on success broadcast to peers with `exclude: reactive_connection_id`, reset composer state, and return `reply.replace.stream(Components::Chat::Message.append(...))` for the actor. Test that `#id` and the rendered reactive root id match.

- [ ] **Step 4: Implement and test the room**

`Room` includes `Phlex::Rails::Helpers::TurboStreamFrom`, calls `turbo_stream_from(*ChatMessage.stream_key(room))`, renders supplied history once into `chat-messages-lobby`, and renders `Composer.new(room:, author:)`. Tests assert the subscription uses the raw key, the target is stable, history is not duplicated, and the real composer root is present.

- [ ] **Step 5: Configure the endpoint boundary**

Set `Phlex::Reactive.base_controller_name = 'ApplicationController'`, `renderer = ApplicationController`, and a concise `error_flash` in the initializer. Render `<div id="<%= Phlex::Reactive.flash_target %>">` in the application layout and assert it in a request test. Keep `Phlex::Reactive.verify_authorized` untouched; authorization is skipped only on `send_message`.

- [ ] **Step 6: Verify green and regression safety**

Run: `bin/rails test test/components/chat/composer_test.rb test/components/chat/room_test.rb && bin/rails test`
Expected: composer and full suite pass.

- [ ] **Step 7: Commit the reactive delivery slice**

Path-limit staging to `app/components/chat/composer.rb`, `app/components/chat/room.rb`, `config/initializers/phlex_reactive.rb`, `app/views/layouts/application.html.erb`, `test/test_helper.rb`, `test/components/chat/composer_test.rb`, and `test/components/chat/room_test.rb`, then commit that slice.

### Task 5: Page Integration And Responsive Interface

**Files:**
- Modify: `app/views/pages/home.rb`
- Modify: `app/views/layouts/application.html.erb`
- Modify: `app/assets/tailwind/application.css`
- Create: `test/integration/chat_page_test.rb`

- [ ] **Step 1: Write failing page integration tests**

Assert guests see the nickname gate but no message composer; named sessions see the lobby, the latest persisted history, nickname change control, stable message list, accessible icon send button, input constraints, and a flash target.

- [ ] **Step 2: Verify red**

Run: `bin/rails test test/integration/chat_page_test.rb`
Expected: old template counter page does not meet chat assertions.

- [ ] **Step 3: Implement the page and gate**

Complete the minimal gate/home branch from Task 2 and replace the counter showcase with the usable lobby. Use a compact identity form, a restrained header, chronological neutral message rows, a scrollable list, and a bottom composer. Use the existing DaisyUI/Tailwind and installed icon helpers; do not add custom JavaScript.

- [ ] **Step 4: Add responsive constraints and accessibility**

Give the chat shell a bounded desktop width and viewport-aware height, ensure the list owns overflow, preserve a stable composer row, wrap long message text, and provide labels/tooltips/focus states. Do not show unsupported presence counts or recipient-specific message alignment.

- [ ] **Step 5: Verify green**

Run: `bin/rails test test/integration/chat_page_test.rb && bin/rails test`
Expected: integration and full suite pass.

- [ ] **Step 6: Commit the interface slice**

Commit the completed page, layout, styles, and integration tests.

### Task 6: End-To-End Verification

**Files:**
- Create: `test/application_system_test_case.rb`
- Create: `test/system/chat_test.rb`
- Modify only if verification exposes a defect.

- [ ] **Step 1: Run automated quality gates**

Run: `bin/rails test`, `bin/rubocop`, `bin/brakeman --no-pager`, and `bin/rails zeitwerk:check`.
Expected: every command exits zero with no test failures or security warnings introduced by the feature.

- [ ] **Step 2: Add the reproducible browser check**

Use Capybara/Selenium as an external-app check with `Capybara.run_server = false`, `Capybara.app_host = 'http://127.0.0.1:45678'`, a 10-second wait, and two named `Capybara.using_session` sessions. Wait in each session for `pgbus-stream-source[connection-id]`. Use a unique body such as `broadcast-#{SecureRandom.hex(6)}`, derive the persisted id from the actor's resulting `#chat_message_<id>` DOM selector rather than the test-process database, and assert exactly that selector once in each session after send and again after reload.

- [ ] **Step 3: Run the two-session browser check**

Start the real development stack with `PORT=45678 bin/dev`, which mounts the pgbus stream engine and runs the real dispatcher. After Rails, Tailwind, and pgbus are ready, run `bin/rails test test/system/chat_test.rb`; the test process drives but does not host the external development app. Stop the development stack after verification. Expected: actor and peer each have exactly one node for the same development-database record id before and after reload.

- [ ] **Step 4: Verify responsive layout**

At `1440x900` and `390x844`, assert the header, message list, and composer are visible; evaluate `document.documentElement.scrollWidth <= document.documentElement.clientWidth`; verify long content wraps and controls do not overlap. Save screenshots to `tmp/screenshots/chat-desktop.png` and `tmp/screenshots/chat-mobile.png`.

- [ ] **Step 5: Review the final diff**

Compare current SHA-256 hashes and `git diff --binary` for `Procfile.dev`, `app/components/counter.rb`, and `bin/setup` against `/tmp/react-demo-chat-baseline/`. They must be byte-for-byte unchanged from baseline and remain unstaged. Review chat-related changes separately; do not expect the overall worktree diff to be clean.

- [ ] **Step 6: Commit any verification fixes**

If verification required changes, add a focused final commit after rerunning the affected gates.
