---
name: phoenix-conventions
description: Phoenix 1.8 / LiveView / Elixir / Ecto / HEEx conventions for this project. Use whenever writing or reviewing Elixir, Phoenix, LiveView, HEEx templates, Ecto schemas, mix tasks, or tests in this repo.
---

# Phoenix conventions (project-local)

Phoenix 1.8 + LiveView + Ecto + Tailwind v4 conventions used in this app. Copied from the upstream `phx.new` usage-rules so they live alongside the code instead of bloating `AGENTS.md`.

## Project-wide

- Use `mix precommit` alias when done with all changes; fix any pending issues.
- Use the included `:req` (`Req`) library for HTTP requests. **Avoid** `:httpoison`, `:tesla`, `:httpc`.

## Phoenix v1.8

- **Always** begin LiveView templates with `<Layouts.app flash={@flash} ...>` wrapping all inner content.
- `MyAppWeb.Layouts` is aliased in `my_app_web.ex` — no extra alias needed.
- Errors with no `current_scope` assign mean Authenticated Routes guidelines weren't followed, or `current_scope` wasn't passed to `<Layouts.app>`. Move routes to the proper `live_session` and pass `current_scope`.
- Phoenix v1.8 moved `<.flash_group>` to the `Layouts` module. **Forbidden** to call `<.flash_group>` outside `layouts.ex`.
- `core_components.ex` imports `<.icon name="hero-x-mark" class="w-5 h-5"/>` for hero icons. **Always** use `<.icon>`, **never** `Heroicons` modules.
- **Always** use the imported `<.input>` from `core_components.ex` for form inputs.
- If you override `<.input>` classes, no defaults are inherited — custom classes must fully style the input.

## JS and CSS

- Use Tailwind CSS classes + custom CSS rules to create polished, responsive interfaces.
- Tailwind v4 **no longer needs `tailwind.config.js`**. Uses this import syntax in `app.css`:

      @import "tailwindcss" source(none);
      @source "../css";
      @source "../js";
      @source "../../lib/my_app_web";

- **Always** maintain this import syntax in `app.css`.
- **Never** use `@apply` when writing raw CSS.
- **Always** manually write tailwind-based components instead of using daisyUI for world-class design.
- Only `app.js` and `app.css` bundles are supported.
  - No external `src`/`href` references in layouts.
  - Import vendor deps into `app.js` and `app.css`.
  - **Never** write inline `<script>custom js</script>` tags in templates.

## UI/UX

- Produce world-class UI: usability, aesthetics, modern design principles.
- Subtle micro-interactions (button hover, smooth transitions).
- Clean typography, spacing, layout balance.
- Delightful details: hover effects, loading states, page transitions.

## Elixir

- Lists **do not support index-based access via access syntax**.

  **Invalid:**

      i = 0
      mylist = ["blue", "green"]
      mylist[i]

  Use `Enum.at`, pattern matching, or `List`:

      Enum.at(mylist, i)

- Variables are immutable but rebindable. For `if`/`case`/`cond` blocks you **must** bind the result; you **cannot** rebind inside the expression:

      # INVALID
      if connected?(socket) do
        socket = assign(socket, :val, val)
      end

      # VALID
      socket =
        if connected?(socket) do
          assign(socket, :val, val)
        end

- **Never** nest multiple modules in the same file (cyclic deps + compile errors).
- **Never** use map access syntax (`changeset[:field]`) on structs. Access fields directly (`my_struct.field`) or use higher-level APIs like `Ecto.Changeset.get_field/2`.
- Use stdlib `Time` / `Date` / `DateTime` / `Calendar`. **Never** install extra deps unless asked, except `date_time_parser` for parsing.
- Don't use `String.to_atom/1` on user input (memory leak risk).
- Predicate names should not start with `is_` and should end in `?`. Names like `is_thing` are reserved for guards.
- OTP primitives like `DynamicSupervisor`, `Registry` require names in child spec: `{DynamicSupervisor, name: MyApp.MyDynamicSup}`, then `DynamicSupervisor.start_child(MyApp.MyDynamicSup, child_spec)`.
- Use `Task.async_stream(collection, callback, options)` for concurrent enumeration with back-pressure. Usually pass `timeout: :infinity`.

## Mix

- Read `mix help task_name` before using tasks.
- Debug failing tests with `mix test test/my_test.exs` or `mix test --failed`.
- `mix deps.clean --all` is **almost never needed**. **Avoid**.

## Tests

- **Always** use `start_supervised!/1` to start processes in tests — guarantees cleanup.
- **Avoid** `Process.sleep/1` and `Process.alive?/1`.
  - Wait for a process to finish: use `Process.monitor/1` + assert DOWN:

        ref = Process.monitor(pid)
        assert_receive {:DOWN, ^ref, :process, ^pid, :normal}

  - Synchronize before next call: use `_ = :sys.get_state/1`.

## Phoenix router

- `scope` blocks include an optional alias prefixed for all routes — be mindful to avoid duplicate prefixes.
- **Never** create your own `alias` for route definitions:

      scope "/admin", AppWeb.Admin do
        pipe_through :browser
        live "/users", UserLive, :index
      end

  `UserLive` → `AppWeb.Admin.UserLive`.

- `Phoenix.View` no longer needed. Don't use it.

## Ecto

- **Always** preload associations in queries when accessed in templates.
- Remember `import Ecto.Query` and supporting modules in `seeds.exs`.
- `Ecto.Schema` fields use `:string` type, even for `:text` columns.
- `Ecto.Changeset.validate_number/2` **DOES NOT SUPPORT `:allow_nil`**. Validations only run if a change exists and isn't nil.
- Access changeset fields via `Ecto.Changeset.get_field(changeset, :field)`.
- Programmatically-set fields (`user_id`, etc) **must not** appear in `cast` calls — set explicitly on struct creation.
- **Always** invoke `mix ecto.gen.migration migration_name_using_underscores` for migrations.

## Phoenix HTML / HEEx

- Templates **always** use `~H` or `.html.heex`. **Never** `~E`.
- **Always** use imported `Phoenix.Component.form/1` + `inputs_for/1`. **Never** `Phoenix.HTML.form_for` or `Phoenix.HTML.inputs_for`.
- When building forms **always** use `Phoenix.Component.to_form/2` (`assign(socket, form: to_form(...))` and `<.form for={@form} id="msg-form">`), then `@form[:field]`.
- **Always** add unique DOM IDs to key elements (forms, buttons) for tests: `<.form for={@form} id="product-form">`.
- App-wide template imports go in `my_app_web.ex`'s `html_helpers` block.

- Elixir supports `if/else` but **does NOT support `if/else if` or `if/elsif`**. Use `cond` or `case`:

      <%= cond do %>
        <% condition -> %>
          ...
        <% condition2 -> %>
          ...
        <% true -> %>
          ...
      <% end %>

- HEEx require `phx-no-curly-interpolation` to insert literal `{` / `}`:

      <code phx-no-curly-interpolation>
        let obj = {key: "val"}
      </code>

- HEEx class attrs **always** use list `[...]` syntax for conditionals:

      <a class={[
        "px-2 text-white",
        @some_flag && "py-5",
        if(@other_condition, do: "border-red-500", else: "border-blue-100")
      ]}>Text</a>

  Wrap `if` inside `{...}` expressions with parens. The non-list form raises a compile syntax error.

- **Never** use `<% Enum.each %>` or non-for comprehensions in templates — always `<%= for item <- @collection do %>`.
- HEEx HTML comments: `<%!-- comment --%>`.
- HEEx interpolation: `{...}` and `<%= ... %>`. `<%= %>` **only** works within tag bodies. Use `{...}` in attributes and tag-body values. Block constructs (`if`, `cond`, `case`, `for`) inside tag bodies use `<%= ... %>`:

      <div id={@id}>
        {@my_assign}
        <%= if @some_block_condition do %>
          {@another_assign}
        <% end %>
      </div>

  **Never** interpolate inside attribute string quotes (`id="<%= ... %>"`) or use block constructs as `{...}` — syntax error.

## Phoenix LiveView

- **Never** use deprecated `live_redirect` / `live_patch`. Use `<.link navigate={href}>` / `<.link patch={href}>` in templates, `push_navigate` / `push_patch` in LiveViews.
- **Avoid LiveComponents** unless there's a strong, specific need.
- LiveViews named `AppWeb.WeatherLive` (`Live` suffix). Router `:browser` scope is already aliased with `AppWeb`: `live "/weather", WeatherLive`.

### LiveView streams

- **Always** use streams for collections to avoid memory ballooning:
  - append: `stream(socket, :messages, [new_msg])`
  - reset: `stream(socket, :messages, [new_msg], reset: true)`
  - prepend: `stream(socket, :messages, [new_msg], at: -1)`
  - delete: `stream_delete(socket, :messages, msg)`

- Template requires `phx-update="stream"` on parent with a DOM id, and each child uses the stream id:

      <div id="messages" phx-update="stream">
        <div :for={{id, msg} <- @streams.messages} id={id}>
          {msg.text}
        </div>
      </div>

- Streams are *not* enumerable. To filter/prune/refresh, refetch + re-stream with `reset: true`:

      def handle_event("filter", %{"filter" => filter}, socket) do
        messages = list_messages(filter)
        {:noreply,
         socket
         |> assign(:messages_empty?, messages == [])
         |> stream(:messages, messages, reset: true)}
      end

- Streams **do not support counting / empty states**. Track count in a separate assign. Empty state via Tailwind:

      <div id="tasks" phx-update="stream">
        <div class="hidden only:block">No tasks yet</div>
        <div :for={{id, task} <- @streams.tasks} id={id}>
          {task.name}
        </div>
      </div>

  Only works if the empty-state block is the only sibling alongside the stream `for`.

- When updating an assign that changes content inside a streamed item, you **must** re-stream the item along with the assign:

      def handle_event("edit_message", %{"message_id" => message_id}, socket) do
        message = Chat.get_message!(message_id)
        edit_form = to_form(Chat.change_message(message, %{content: message.content}))

        {:noreply,
         socket
         |> stream_insert(:messages, message)
         |> assign(:editing_message_id, String.to_integer(message_id))
         |> assign(:edit_form, edit_form)}
      end

- **Never** use deprecated `phx-update="append"` / `"prepend"`.

### LiveView JS interop

- `phx-hook="MyHook"` with a JS hook managing its own DOM **must** also set `phx-update="ignore"`.
- **Always** provide a unique DOM id alongside `phx-hook` (compile error otherwise).

Two hook flavors: colocated `:type={Phoenix.LiveView.ColocatedHook}` for inline, and external `phx-hook` annotations.

#### Inline colocated

**Never** write raw `<script>` tags in heex — incompatible with LiveView. Use a colocated hook script tag:

    <input type="text" name="user[phone_number]" id="user-phone-number" phx-hook=".PhoneNumber" />
    <script :type={Phoenix.LiveView.ColocatedHook} name=".PhoneNumber">
      export default {
        mounted() {
          this.el.addEventListener("input", e => {
            let match = this.el.value.replace(/\D/g, "").match(/^(\d{3})(\d{3})(\d{4})$/)
            if(match) {
              this.el.value = `${match[1]}-${match[2]}-${match[3]}`
            }
          })
        }
      }
    </script>

- Colocated hooks integrate into `app.js` automatically.
- Names **must always** start with `.` prefix.

#### External phx-hook

External hooks (`<div id="myhook" phx-hook="MyHook">`) live in `assets/js/` and pass to `LiveSocket`:

    const MyHook = { mounted() { ... } }
    let liveSocket = new LiveSocket("/live", Socket, { hooks: { MyHook } });

#### Push events client ↔ server

Use `push_event/3` to push to client. **Always** return or rebind the socket:

    socket = push_event(socket, "my_event", %{...})

    def handle_event("some_event", _, socket) do
      {:noreply, push_event(socket, "my_event", %{...})}
    end

JS hook handler:

    mounted() {
      this.handleEvent("my_event", data => console.log("from server:", data));
    }

Client → server with reply:

    mounted() {
      this.el.addEventListener("click", e => {
        this.pushEvent("my_event", { one: 1 }, reply => console.log("got reply:", reply));
      })
    }

Server reply:

    def handle_event("my_event", %{"one" => 1}, socket) do
      {:reply, %{two: 2}, socket}
    end

### LiveView tests

- Use `Phoenix.LiveViewTest` + `LazyHTML` for assertions.
- Form tests use `render_submit/2` and `render_change/2`.
- Plan tests step-by-step, split into small isolated files. Start with content-existence, add interaction.
- **Always** reference the key element IDs added to templates in tests.
- **Never** test against raw HTML. Use `element/2`, `has_element/2`: `assert has_element?(view, "#my-form")`.
- Favor testing presence of key elements over text content.
- Test outcomes, not implementation details.
- `Phoenix.Component` functions like `<.form>` may produce different HTML than expected. Test against actual output structure.
- For element-selector failures, debug with `LazyHTML`:

      html = render(view)
      document = LazyHTML.from_fragment(html)
      matches = LazyHTML.filter(document, "your-complex-selector")
      IO.inspect(matches, label: "Matches")

### Forms

#### From params

    def handle_event("submitted", params, socket) do
      {:noreply, assign(socket, form: to_form(params))}
    end

Passing a map to `to_form/1` assumes it contains form params (string keys). To nest:

    def handle_event("submitted", %{"user" => user_params}, socket) do
      {:noreply, assign(socket, form: to_form(user_params, as: :user))}
    end

#### From changesets

Underlying data, params, errors, and `:as` are auto-computed:

    %MyApp.Users.User{}
    |> Ecto.Changeset.change()
    |> to_form()

Submitted params land under `%{"user" => user_params}`.

In template:

    <.form for={@form} id="todo-form" phx-change="validate" phx-submit="save">
      <.input field={@form[:field]} type="text" />
    </.form>

Always give the form an explicit, unique DOM ID.

#### Avoiding form errors

**Always** use `to_form/2` in the LiveView + `<.input>` in the template. Access via:

    <%!-- VALID --%>
    <.form for={@form} id="my-form">
      <.input field={@form[:field]} type="text" />
    </.form>

**Never** do this:

    <%!-- INVALID --%>
    <.form for={@changeset} id="my-form">
      <.input field={@changeset[:field]} type="text" />
    </.form>

- You are FORBIDDEN from accessing the changeset in the template — errors.
- **Never** use `<.form let={f} ...>`. **Always** `<.form for={@form} ...>` and drive references via `@form[:field]`. UI **always** driven by `to_form/2` assigned in the LiveView from a changeset.
