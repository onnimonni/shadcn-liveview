defmodule ConsumerWeb.SettingsView do
  use Phoenix.Component
  use ShadcnLiveview

  attr :id, :string, required: true
  attr :form, Phoenix.HTML.Form, required: true
  attr :saved, :any, required: true
  attr :revision, :integer, required: true
  attr :pending, :any, default: nil
  attr :dialog_open, :boolean, default: false
  attr :status, :string, required: true
  attr :target, :any, default: nil

  def editor(assigns) do
    assigns = assign(assigns, :timezones, Consumer.Settings.timezones())

    ~H"""
    <div id={@id <> "-editor"} class="settings-grid">
      <section class="settings-panel" aria-labelledby={@id <> "-heading"}>
        <h2 id={@id <> "-heading"}>Edit your preferences</h2>
        <.form
          for={@form}
          id={@id <> "-form"}
          phx-change="validate"
          phx-submit="save"
          phx-auto-recover="recover"
          phx-target={@target}
          novalidate
        >
          <div class="settings-fields">
            <.form_field
              :let={attrs}
              field={@form[:email]}
              label="Email"
              description="Used for account notifications."
              required
            >
              <.input {attrs} type="email" autocomplete="email" />
            </.form_field>
            <.form_field
              :let={attrs}
              field={@form[:display_name]}
              label="Display name"
              description="Between 2 and 60 characters."
              required
            >
              <.input {attrs} autocomplete="name" />
            </.form_field>
            <.form_field
              :let={attrs}
              field={@form[:timezone]}
              label="Timezone"
              description="Your preferred timezone for scheduled updates."
              required
            >
              <.native_select :let={selection} {attrs}>
                <option
                  :for={timezone <- @timezones}
                  value={timezone}
                  selected={timezone in selection}
                >
                  {timezone}
                </option>
              </.native_select>
            </.form_field>
            <.form_field
              :let={attrs}
              field={@form[:notifications]}
              label="Email notifications"
              description="Receive product updates by email."
              orientation="horizontal"
            >
              <.checkbox {attrs} />
            </.form_field>
            <.form_field
              :let={attrs}
              field={@form[:bio]}
              label="Bio"
              description="A short introduction, up to 280 characters."
            >
              <.textarea {attrs} rows="4" />
            </.form_field>
          </div>
          <div class="settings-actions">
            <.button id={@id <> "-save"} type="submit" phx-disable-with="Validating…">Review and save</.button>
            <.button
              id={@id <> "-reset"}
              type="button"
              variant="outline"
              phx-click="reset"
              phx-target={@target}
            >Reset to saved</.button>
            <.button
              id={@id <> "-server-update"}
              type="button"
              variant="secondary"
              phx-click="server-update"
              phx-target={@target}
            >Apply server update</.button>
          </div>
        </.form>
        <p id={@id <> "-status"} class="settings-status" role="status" aria-live="polite">
          {@status}
        </p>
        <p class="settings-note">
          Server update deliberately replaces the draft with new saved values. Reset discards only unsaved edits.
          Open the other route in a second tab to see shared saved state.
        </p>
      </section>
      <section class="settings-panel" aria-labelledby={@id <> "-result-heading"}>
        <h2 id={@id <> "-result-heading"}>Live server result</h2>
        <p class="settings-note">
          Saved revision <strong id={@id <> "-revision"}>{@revision}</strong>
        </p>
        <dl id={@id <> "-result"} class="settings-result" aria-live="polite">
          <dt>Email</dt><dd data-saved="email">{@saved.email}</dd>
          <dt>Display name</dt><dd data-saved="display_name">{@saved.display_name}</dd>
          <dt>Timezone</dt><dd data-saved="timezone">{@saved.timezone}</dd>
          <dt>Notifications</dt><dd data-saved="notifications">{to_string(@saved.notifications)}</dd>
          <dt>Bio</dt><dd data-saved="bio">{@saved.bio}</dd>
        </dl>
        <p class="settings-note">
          This isolated example stores settings in a supervised server process, keyed by your browser session.
          Saves survive LiveView reconnects and page reloads, but not an application restart. No production database is implied.
        </p>
        <p class="settings-note">
          To try Phoenix form recovery, edit without saving, disconnect the network, then reconnect without reloading.
          The form's stable ID and phx-auto-recover replay your unsaved inputs to the server.
        </p>
      </section>
      <.dialog
        id={@id <> "-save-dialog"}
        open={@dialog_open}
        target={@target}
        trigger_id={@id <> "-save"}
      >
        <:content :let={modal}>
          <.dialog_content
            context={modal}
            aria-labelledby={modal.title_id}
            aria-describedby={modal.description_id}
          >
            <.dialog_header>
              <.dialog_title context={modal}>Confirm settings save</.dialog_title>
              <.dialog_description context={modal}>
                Save these validated preferences to the example server, or return to editing.
              </.dialog_description>
            </.dialog_header>
            <p :if={@pending} class="settings-dialog-summary">
              Saving <strong>{@pending.display_name}</strong>
              ({@pending.email}) in {@pending.timezone},
              with email notifications {if @pending.notifications, do: "enabled", else: "disabled"}.
            </p>
            <.dialog_footer>
              <.dialog_close context={modal}>Continue editing</.dialog_close>
              <.button
                id={@id <> "-confirm"}
                type="button"
                phx-click="confirm-save"
                phx-target={@target}
                phx-disable-with="Saving…"
              >Confirm save</.button>
            </.dialog_footer>
          </.dialog_content>
        </:content>
      </.dialog>
      <.toaster id={@id <> "-toaster"} />
    </div>
    """
  end
end
