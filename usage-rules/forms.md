# Forms with shadcn_liveview

## Composition

Assign `@form` with `to_form/2` (Ecto changeset or params map) and wrap every control in
`form_field`. It renders the label, description and errors, sets `id`/`name`/value from the
field, and yields `attrs` (ARIA wiring) to spread on exactly one control:

```heex
<.form for={@form} id="profile-form" phx-change="validate" phx-submit="save">
  <.form_field :let={a} field={@form[:email]} label="Email" description="For receipts." required>
    <.input {a} type="email" autocomplete="email" />
  </.form_field>
  <.form_field :let={a} field={@form[:bio]} label="Bio">
    <.textarea {a} rows="4" />
  </.form_field>
  <.form_field :let={a} field={@form[:team_size]} label="Team size">
    <.native_select :let={selected} {a}>
      <.native_select_option :for={{label, value} <- @sizes} value={value} selected={value in selected}>
        {label}
      </.native_select_option>
    </.native_select>
  </.form_field>
  <.form_field :let={a} field={@form[:plan]} label="Plan">
    <.radio_group :let={group} {a}>
      <div :for={p <- ~w(free pro)} class="flex items-center gap-2">
        <.radio_group_item context={group} id={"plan-" <> p} value={p} />
        <.label for={"plan-" <> p}>{String.capitalize(p)}</.label>
      </div>
    </.radio_group>
  </.form_field>
  <.form_field :let={a} field={@form[:terms]} label="I accept the terms" orientation="horizontal" required>
    <.checkbox {a} />
  </.form_field>
  <.form_field :let={a} field={@form[:marketing]} label="Product updates" orientation="horizontal">
    <.switch {a} />
  </.form_field>
  <.button type="submit" class="phx-submit-loading:opacity-60">Save</.button>
</.form>
```

In an app set up with `mix shadcn_liveview.install`, `<.input>` is the app's CoreComponents
wrapper, which renders its own label and errors: write `<.input field={@form[:email]}
label="Email" />` there, not inside `form_field`. Inside `form_field`, call the library control
by module (`<ShadcnLiveview.Components.Input.input {a} />`); `textarea`, `native_select`,
`checkbox`, `switch` and `radio_group` are the library versions in both setups.

- Supported field-bound controls: `input`, `textarea`, `native_select`, `checkbox`, `switch`,
  `radio_group`. Explicit attrs override inferred ones.
- Use `orientation="horizontal"` for checkbox/switch: control first, text beside it.
- Binary controls submit `"false"` unchecked and `"true"` checked (hidden input + checkbox).
- `native_select` yields the selected values (strings) to `:let`; mark options with
  `selected={value in selected}` and use `native_select_option` for option styling.
- Prefer `native_select` in forms; `select` is a styled listbox driven by `on_change` events.
- Rich label content (links to terms): omit `label` and pass `<:label_content>…</:label_content>`
  inside `form_field`; exactly one of the two is required.
- Composing `field` by hand (a label row with a "Forgot password?" link): pass
  `<.field invalid={@errors != []}>`; a boolean `data-invalid` renders an empty attribute that
  the invalid styles (`data-[invalid=true]`) don't match.

## Validation

- Errors render only for fields Phoenix considers used (`used_input?/1`). Keep LiveView's
  `_unused_*` params when you normalize/whitelist attrs, or every untouched field shows errors
  on the first keystroke.
- Trimming must be nil-safe: a cleared field casts to `nil`, so
  `update_change(cs, :name, &String.trim/1)` crashes the LiveView. Trim params before `cast` or
  use `&(&1 && String.trim(&1))`.
- Don't put seed values in schema `default:`; `cast/4` replaces a cleared field with the schema
  default, so "clearing" silently restores it and `validate_required` never fires. Seed initial
  data explicitly, and don't pass `empty_values: []`.
- Validating first does not make the write safe: recheck existence/ownership when you mutate
  (a record deleted between validate and save must not be resurrected).
- Run changesets in the LiveView/context, not inside a shared GenServer; invalid input must never
  crash shared state.
- On `validate`, assign `to_form(Map.put(changeset, :action, :validate))`; on failed submit, set
  `:action` (`:insert`/`:update`) so every field shows errors.
- Without Ecto (demos, a converted login page), use a params map and attach errors yourself:
  `to_form(params, as: :login, errors: [email: {"can't be blank", []}], action: :validate)`;
  `form_field` shows them only for used fields, exactly as with a changeset.
- Keep errors beside the control (form_field does this). A page-top summary alone can be
  off-screen on mobile; if you add one, link each item to its field id.
- After an invalid submit, move focus to the first invalid field (small app hook that runs after
  the patch), because focus otherwise stays on the submit button.

## Recovery and disconnects

- Give forms a stable `id` and `phx-auto-recover` when the default recovery is not enough.
- Disable unsafe submits while disconnected (`phx-disconnected`/`phx-connected` JS or CSS on
  `.phx-loading` plus a real `disabled`), not just with opacity.

## Tests

- LiveViewTest's `form/3` only accepts inputs that exist in the DOM, so send touched-only
  markers with the event directly:
  `render_change(view, "validate", %{"signup" => %{"name" => "A", "email" => "", "_unused_email" => ""}})`,
  then assert the name error renders and the email error does not. `render_submit/2` covers
  submitted errors.
- Browser: clear a pre-filled required field; toggle two binary controls then immediately type in
  another field and assert `new FormData(form)` matches `aria-checked`.
