defmodule ShadcnLiveview.Components.Questionnaire do
  @moduledoc """
  Caller-controlled questionnaire state with explicit root and item :let contexts. Supply items (name, required, disabled and choices maps), an optional item name, statuses and invalid names. The native form hook initializes controls, validates all enabled questions, supports keyboard navigation, resets answers, and dispatches questionnaire:item-change plus an optional LiveView on_item_change event. Server patches remain authoritative; hidden fieldsets are inert, not disabled, so answered questions remain in FormData.
  Hook navigation and reset events honor phx-target on the form or nearest containing element. Scalar forms use Phoenix's native form transport. Forms with multiple-answer items push configured phx-change/phx-submit events with array values, preserving successful DOM field names; changes include _target and an empty array when the last choice is cleared.
  """
  use Phoenix.Component
  import ShadcnLiveview.Helpers
  alias ShadcnLiveview.Components.Icon

  @doc "Renders a native form and yields a context for steps, progress and navigation."
  attr :id, :string, required: true
  attr :items, :list, default: []
  attr :item, :string, default: nil
  attr :statuses, :map, default: %{}
  attr :invalid, :list, default: []
  attr :shortcuts, :string, values: [nil, "letters", "numbers"], default: nil
  attr :on_item_change, :string, default: nil
  attr :no_validate, :boolean, default: true
  attr :class, :string, default: nil

  attr :rest, :global,
    include:
      ~w(aria-label aria-describedby aria-keyshortcuts role tabindex form name placeholder autocomplete min max step minlength maxlength pattern readonly type value disabled required)

  slot :inner_block

  def questionnaire(assigns) do
    enabled = Enum.reject(assigns.items, &Map.get(&1, :disabled, false))
    item = assigns.item || (List.first(enabled) || %{})[:name]
    index = Enum.find_index(enabled, &(&1.name == item))
    current = if is_nil(index), do: 0, else: index + 1
    total = length(enabled)
    definition = Enum.find(enabled, &(&1.name == item))

    context = %{
      id: assigns.id,
      item: item,
      current: current,
      total: total,
      first: current == 1,
      last: total > 0 and current == total,
      required: if(definition, do: Map.get(definition, :required, false)),
      status: if(definition, do: Map.get(assigns.statuses, item, "unanswered")),
      statuses: assigns.statuses,
      invalid: assigns.invalid,
      shortcuts: assigns.shortcuts,
      items: assigns.items
    }

    assigns = assign(assigns, :context, context)

    ~H"""
    <form
      id={@id}
      data-slot="questionnaire"
      data-current={@context.current}
      data-total={@context.total}
      data-first={if @context.first, do: ""}
      data-last={if @context.last, do: ""}
      data-shortcuts={@shortcuts}
      novalidate={@no_validate}
      phx-hook=".Questionnaire"
      phx-value-item={@context.item}
      phx-value-on-item-change={@on_item_change}
      class={classes([~S|flex w-full min-w-0 flex-col gap-4|, @class])}
      {@rest}
    >
      {render_slot(@inner_block, @context)}
    </form>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Questionnaire">
        export default {
      sendEvent(event, payload, onReply) {
      const target = this.el.closest('[phx-target]')?.getAttribute("phx-target");
      if (target) return this.pushEventTo(target, event, payload, onReply);
      return this.pushEvent(event, payload, onReply);
      },
      mounted() {
      this.states = new Map(); this.controlDefaults = new Map(); this.initialItem = this.el.getAttribute("phx-value-item"); this.current = this.initialItem; this.serverItem = this.initialItem;
      this.change = e => {
        const fieldset = e.target.closest('[data-slot="questionnaire-item"]'); if (!fieldset) return;
        const state = this.state(fieldset); state.skipped = false;
        this.refresh();
        const event = this.items().some(item => item.hasAttribute("data-multiple")) && this.el.getAttribute("phx-change");
        if (event) {
          // Phoenix's URL-encoded form transport collapses repeated unbracketed
          // names. Keep vendor DOM/FormData names and push the typed values instead.
          e.stopPropagation();
          if (e.isComposing || e.type === "change" && this.arrayInput === e.target) return;
          if (e.type === "input") {
            const input = e.target; this.arrayInput = input;
            queueMicrotask(() => { if (this.arrayInput === input) this.arrayInput = null; });
          }
          this.sendEvent(event, { ...this.formPayload(undefined, fieldset.getAttribute("phx-value-name")), _target: [fieldset.getAttribute("phx-value-name")] });
        }
      };
      this.click = e => {
        const button = e.target.closest("button[data-slot]"); if (!button || !this.el.contains(button) || button.disabled) return;
        const slot = button.dataset.slot;
        if (slot === "questionnaire-previous") this.move(-1);
        if (slot === "questionnaire-next") this.advance();
        if (slot === "questionnaire-skip") this.skip();
      };
      this.submit = e => {
        const invalid = this.items().find(item => !this.validate(item));
        if (invalid) { e.preventDefault(); e.stopImmediatePropagation(); this.select(invalid, true); }
        else {
          const event = this.items().some(item => item.hasAttribute("data-multiple")) && this.el.getAttribute("phx-submit");
          if (event) {
            e.preventDefault(); e.stopImmediatePropagation();
            this.sendEvent(event, this.formPayload(e.submitter));
          }
        }
      };
      this.reset = e => { queueMicrotask(() => {
        if (e.defaultPrevented) return;
        this.states.clear(); this.initialize(true);
        const initial = this.items().find(item => item.getAttribute("phx-value-name") === this.initialItem) || this.items()[0];
        if (initial) this.select(initial); else this.refresh();
      }); };
      this.key = e => {
        if (e.defaultPrevented || e.isComposing || e.keyCode === 229) return;
        const active = this.active(); if (!active) return;
        const controls = this.controls(active); const target = e.target;
        const editing = target.matches('textarea,select,input:not([type=radio]):not([type=checkbox]):not([type=button]):not([type=submit])') || target.isContentEditable;
        if (e.key === "Enter" && (e.metaKey || e.ctrlKey) && !e.altKey && !e.shiftKey) { e.preventDefault(); if (!e.repeat) this.advance(); return; }
        if (e.metaKey || e.ctrlKey || e.altKey) return;
        if (["ArrowUp", "ArrowDown"].includes(e.key) && (!editing || target.value.trim() === "")) {
          const index = controls.indexOf(target); if (index < 0 && target !== active || !controls.length) return;
          const next = index < 0 ? controls.find(control => control.checked) || (e.key === "ArrowDown" ? controls[0] : controls[controls.length - 1]) : controls[(index + (e.key === "ArrowDown" ? 1 : controls.length - 1) + controls.length) % controls.length];
          if (next === target || target.type === "radio" && next.type === "radio") return;
          e.preventDefault(); next.focus(); if (next.type === "radio") next.click(); return;
        }
        if (["ArrowLeft", "ArrowRight"].includes(e.key) && !editing && target.type !== "radio") {
          e.preventDefault(); if (!e.repeat) { if (e.key === "ArrowLeft") this.move(-1); else if (active.dataset.status !== "unanswered") this.advance(); } return;
        }
        if (e.key === "Enter" && controls.includes(target)) { e.preventDefault(); if (!e.repeat && (target.matches('input[type=radio],input[type=checkbox]') ? target.checked : target.value.trim() !== "")) this.advance(); return; }
        if (editing || e.repeat) return;
        const shortcut = this.el.dataset.shortcuts === "letters" ? e.key.toUpperCase() : e.key;
        const choice = controls.find(input => input.dataset.shortcut === shortcut);
        if (choice) { e.preventDefault(); choice.focus(); choice.click(); }
      };
      this.el.addEventListener("input", this.change); this.el.addEventListener("change", this.change);
      this.el.addEventListener("click", this.click); this.el.addEventListener("submit", this.submit, true);
      this.el.addEventListener("reset", this.reset); this.el.addEventListener("keydown", this.key);
      this.initialize(); this.refresh();
      },
      formPayload(submitter, changedName) {
      const data = submitter ? new FormData(this.el, submitter) : new FormData(this.el);
      const multiple = new Set(this.items().filter(item => item.hasAttribute("data-multiple")).map(item => item.getAttribute("phx-value-name")));
      const payload = { id: this.el.id };
      for (const name of new Set(data.keys())) payload[name] = multiple.has(name) ? data.getAll(name) : data.get(name);
      if (multiple.has(changedName) && !data.has(changedName)) payload[changedName] = [];
      return payload;
      },
      items() { return Array.from(this.el.querySelectorAll('[data-slot="questionnaire-item"]')).filter(item => !item.disabled); },
      controls(item) { return Array.from(item.querySelectorAll('[data-slot="questionnaire-choice-input"], [data-slot="questionnaire-input"]')).filter(control => !control.disabled); },
      state(item) {
      const name = item.getAttribute("phx-value-name");
      if (!this.states.has(name)) {
        const serverStatus = item.getAttribute("phx-value-server-status");
        this.states.set(name, { serverStatus, skipped: serverStatus === "skipped", attempted: false, invalid: item.getAttribute("phx-value-server-invalid") === "true" });
      }
      return this.states.get(name);
      },
      initialize(reset = false) {
      this.items().forEach(item => {
        this.state(item);
        this.controls(item).forEach(input => {
          const choice = input.dataset.slot === "questionnaire-choice-input";
          let defaults = this.controlDefaults.get(input.id);
          if (!defaults) {
            defaults = { checked: input.checked || input.getAttribute("phx-value-default-checked") === "true", value: input.defaultValue };
            this.controlDefaults.set(input.id, defaults);
            if (choice) input.checked = defaults.checked;
          }
          if (reset) { if (choice) input.checked = defaults.checked; else input.value = defaults.value; }
        });
      });
      },
      active() { return this.items().find(item => item.getAttribute("phx-value-name") === this.current); },
      answered(item) { return this.controls(item).some(input => input.matches('input[type=radio],input[type=checkbox]') ? input.checked : input.value.trim() !== ""); },
      validate(item) {
      const state = this.state(item); state.attempted = true;
      const valid = state.skipped && !item.hasAttribute("data-required") || !state.invalid && this.answered(item);
      if (!valid) { this.refresh(); return false; }
      if (!this.el.noValidate) {
        const invalid = this.controls(item).find(input => (input.checked || !input.matches('input[type=radio],input[type=checkbox]') && input.value.trim() !== "") && !input.validity.valid);
        if (invalid) { invalid.focus(); invalid.reportValidity(); return false; }
      }
      return true;
      },
      select(item, invalid = false) {
      if (!item) return;
      const name = item.getAttribute("phx-value-name"); const changed = this.current !== name; this.current = name; this.refresh();
      if (invalid) (this.controls(item)[0] || item).focus(); else item.focus();
      if (changed) {
        this.el.dispatchEvent(new CustomEvent("questionnaire:item-change", { bubbles: true, detail: { item: name } }));
        const event = this.el.getAttribute("phx-value-on-item-change"); if (event) this.sendEvent(event, { id: this.el.id, value: name });
      }
      },
      move(delta) { const items = this.items(); const index = items.indexOf(this.active()); this.select(items[index + delta]); },
      advance() { const item = this.active(); if (!item) return; if (!this.validate(item)) { this.select(item, true); return; } const items = this.items(); const next = items[items.indexOf(item) + 1]; if (next) this.select(next); else this.el.requestSubmit(); },
      skip() {
      const item = this.active(); if (!item || item.hasAttribute("data-required")) return;
      const state = this.state(item); state.skipped = true; state.attempted = false;
      this.controls(item).forEach(input => { if (input.matches('input[type=radio],input[type=checkbox]')) input.checked = false; });
      this.refresh(); const items = this.items(); const next = items[items.indexOf(item) + 1]; if (next) this.select(next); else this.el.requestSubmit();
      },
      flag(element, attribute, enabled) { if (enabled) element.setAttribute(attribute, ""); else element.removeAttribute(attribute); },
      refresh() {
      const items = this.items(); let active = this.active();
      if (!active) { active = items[0]; this.current = active ? active.getAttribute("phx-value-name") : null; }
      const current = active ? items.indexOf(active) + 1 : 0; const total = items.length;
      const first = current === 1; const last = total > 0 && current === total;
      this.el.dataset.current = current; this.el.dataset.total = total; this.flag(this.el,"data-first",first); this.flag(this.el,"data-last",last);
      this.el.querySelectorAll('[data-slot="questionnaire-item"]').forEach(item => {
        const state = this.state(item); const enabled = !item.disabled;
        const status = state.skipped ? "skipped" : this.answered(item) ? "answered" : "unanswered";
        const invalid = enabled && !state.skipped && (state.invalid || state.attempted && status !== "answered");
        const isActive = enabled && item === active; item.dataset.status = status;
        this.flag(item,"data-active",isActive); this.flag(item,"data-invalid",invalid);
        item.hidden = !isActive; item.inert = !isActive;
        if (invalid) item.setAttribute("aria-invalid","true"); else item.removeAttribute("aria-invalid");
        const controls = this.controls(item);
        const keys = isActive ? ["Meta+Enter Control+Enter", controls.length ? "ArrowUp ArrowDown" : "", !first ? "ArrowLeft" : "", !last && status !== "unanswered" ? "ArrowRight" : ""].filter(Boolean).join(" ") : "";
        if (keys) item.setAttribute("aria-keyshortcuts",keys); else item.removeAttribute("aria-keyshortcuts");
        const descriptions = Array.from(item.querySelectorAll('[data-slot="questionnaire-description"], [data-slot="questionnaire-error"]')).filter(node => node.dataset.slot !== "questionnaire-error" || invalid).map(node => node.id);
        const original = item.getAttribute("phx-value-describedby"); if (original) descriptions.push(original);
        if (!item.hasAttribute("phx-value-describedby")) item.setAttribute("phx-value-describedby", item.getAttribute("aria-describedby") || "");
        if (descriptions.length) item.setAttribute("aria-describedby", descriptions.join(" ")); else item.removeAttribute("aria-describedby");
        item.querySelectorAll('[data-slot="questionnaire-choice-input"], [data-slot="questionnaire-input"]').forEach(input => {
          const choice = input.dataset.slot === "questionnaire-choice-input";
          const selected = !state.skipped && (choice ? input.checked : input.value.trim() !== "");
          const name = item.getAttribute("phx-value-name");
          if (choice || selected) { input.removeAttribute("form"); if (!state.skipped) input.name = name; else input.removeAttribute("name"); }
          else { input.removeAttribute("name"); input.setAttribute("form", ""); }
          if (choice) {
            input.required = item.hasAttribute("data-required") && !item.hasAttribute("data-multiple") && !controls.some(control => control.dataset.slot === "questionnaire-input");
            [input, input.closest('[data-slot="questionnaire-choice"]')].forEach(node => { this.flag(node,"data-checked",input.checked); this.flag(node,"data-unchecked",!input.checked); this.flag(node,"data-invalid",invalid); });
          } else { this.flag(input,"data-filled",selected); this.flag(input,"data-empty",!selected); this.flag(input,"data-invalid",invalid); }
          if (invalid) input.setAttribute("aria-invalid","true"); else input.removeAttribute("aria-invalid");
          const shortcut = [input.dataset.shortcut, selected && !input.disabled ? "Enter" : null].filter(Boolean).join(" ");
          if (shortcut) input.setAttribute("aria-keyshortcuts",shortcut); else input.removeAttribute("aria-keyshortcuts");
        });
        item.querySelectorAll('[data-slot="questionnaire-error"]').forEach(error => { error.hidden = !invalid; this.flag(error,"data-invalid",invalid); if (invalid) error.setAttribute("role","alert"); else error.removeAttribute("role"); });
      });
      this.el.querySelectorAll('[data-slot="questionnaire-progress"]').forEach(progress => {
        progress.dataset.current = current; progress.dataset.total = total; this.flag(progress,"data-first",first); this.flag(progress,"data-last",last);
        const text = total ? "Question " + current + " of " + total : "";
        if (progress.getAttribute("phx-value-custom") !== "true") progress.textContent = text;
        ["aria-valuemin","aria-valuemax","aria-valuenow","aria-valuetext"].forEach(attr => { if (!total) progress.removeAttribute(attr); });
        if (total) { progress.setAttribute("aria-valuemin","1"); progress.setAttribute("aria-valuemax",total); progress.setAttribute("aria-valuenow",current); progress.setAttribute("aria-valuetext",text); }
      });
      ["previous","skip","next","submit"].forEach(action => this.el.querySelectorAll('[data-slot="questionnaire-' + action + '"]').forEach(button => {
        const visible = action === "previous" ? total > 1 && !first : action === "skip" ? !!active && !active.hasAttribute("data-required") : action === "next" ? total > 1 && !last : total > 0 && last;
        this.flag(button,"data-visible",visible); this.flag(button,"data-hidden",!visible); button.hidden = !visible; button.inert = !visible;
        if (!visible) { button.setAttribute("aria-hidden","true"); button.tabIndex = -1; } else { button.removeAttribute("aria-hidden"); const tab = button.getAttribute("phx-value-tabindex"); if (tab) button.tabIndex = Number(tab); else button.removeAttribute("tabindex"); }
        if (active) button.dataset.status = active.dataset.status; else button.removeAttribute("data-status");
        const shortcut = visible && !button.disabled && ["next","submit"].includes(action);
        if (shortcut) { button.dataset.shortcut = "Enter"; button.setAttribute("aria-keyshortcuts","Enter"); } else { delete button.dataset.shortcut; button.removeAttribute("aria-keyshortcuts"); }
      }));
      },
      beforeUpdate() {
      this.controlSnapshot = new Map(Array.from(this.el.querySelectorAll('input[data-slot]')).map(input => [input.id, {
        value: input.value, checked: input.checked, serverValue: input.getAttribute("value"), serverChecked: input.hasAttribute("checked")
      }]));
      },
      updated() {
      this.el.querySelectorAll('input[data-slot]').forEach(input => {
        const previous = this.controlSnapshot && this.controlSnapshot.get(input.id);
        if (!previous) return;
        const defaults = this.controlDefaults.get(input.id);
        if (input.getAttribute("value") === previous.serverValue) input.value = previous.value;
        else if (defaults) defaults.value = input.defaultValue;
        if (input.hasAttribute("checked") === previous.serverChecked) input.checked = previous.checked;
        else if (defaults) defaults.checked = input.checked;
      });
      const item = this.el.getAttribute("phx-value-item"); if (item !== this.serverItem) { this.current = item; this.serverItem = item; }
      this.el.querySelectorAll('[data-slot="questionnaire-item"]').forEach(fieldset => {
        const state = this.state(fieldset); state.invalid = fieldset.getAttribute("phx-value-server-invalid") === "true";
        const serverStatus = fieldset.getAttribute("phx-value-server-status");
        if (serverStatus !== state.serverStatus) { state.skipped = serverStatus === "skipped"; state.serverStatus = serverStatus; }
      });
      this.initialize(); this.refresh();
      },
      destroyed() {
      this.el.removeEventListener("input",this.change); this.el.removeEventListener("change",this.change); this.el.removeEventListener("click",this.click);
      this.el.removeEventListener("submit",this.submit,true); this.el.removeEventListener("reset",this.reset); this.el.removeEventListener("keydown",this.key);
      }
      }
    </script>
    """
  end

  attr :context, :map, required: true
  attr :class, :string, default: nil

  attr :rest, :global,
    include:
      ~w(aria-label aria-describedby aria-keyshortcuts role tabindex form name placeholder autocomplete min max step minlength maxlength pattern readonly type value disabled required)

  slot :inner_block

  def questionnaire_progress(assigns) do
    assigns =
      assign(
        assigns,
        :text,
        if(assigns.context.total > 0,
          do: "Question #{assigns.context.current} of #{assigns.context.total}"
        )
      )

    ~H"""
    <div
      data-slot="questionnaire-progress"
      data-current={@context.current}
      data-total={@context.total}
      phx-value-custom={to_string(@inner_block != [])}
      data-first={if @context.first, do: ""}
      data-last={if @context.last, do: ""}
      role="progressbar"
      aria-label="Questionnaire progress"
      aria-live="polite"
      aria-valuemin={if @context.total > 0, do: 1}
      aria-valuemax={if @context.total > 0, do: @context.total}
      aria-valuenow={if @context.total > 0, do: @context.current}
      aria-valuetext={@text}
      class={
        classes([
          ~S|min-h-[1lh] w-fit min-w-[14ch] text-xs font-medium text-muted-foreground tabular-nums|,
          @class
        ])
      }
      {@rest}
    >
      <%= if @inner_block == [] do %>
        {@text}
      <% else %>
        {render_slot(@inner_block, @context)}
      <% end %>
    </div>
    """
  end

  @doc "A valid fieldset with explicit name and item state, yielding context for answer controls."
  attr :context, :map, required: true
  attr :name, :string, required: true
  attr :disabled, :boolean, default: false
  attr :required, :boolean, default: false
  attr :multiple, :boolean, default: false
  attr :invalid, :boolean, default: false
  attr :status, :string, default: nil, values: [nil, "unanswered", "answered", "skipped"]
  attr :class, :string, default: nil

  attr :rest, :global,
    include:
      ~w(aria-label aria-describedby aria-keyshortcuts role tabindex form name placeholder autocomplete min max step minlength maxlength pattern readonly type value disabled required)

  slot :inner_block

  def questionnaire_item(assigns) do
    active = not assigns.disabled and assigns.context.item == assigns.name
    status = assigns.status || Map.get(assigns.context.statuses, assigns.name, "unanswered")

    invalid =
      not assigns.disabled and status != "skipped" and
        (assigns.invalid or assigns.name in assigns.context.invalid)

    keys = item_keyshortcuts(active, assigns.context, status)

    context =
      Map.merge(assigns.context, %{
        name: assigns.name,
        active: active,
        disabled: assigns.disabled,
        required: assigns.required,
        multiple: assigns.multiple,
        invalid: invalid,
        status: status
      })

    assigns = assign(assigns, context: context, keys: keys)

    ~H"""
    <fieldset
      data-slot="questionnaire-item"
      data-active={if @context.active, do: ""}
      data-disabled={if @disabled, do: ""}
      data-invalid={if @context.invalid, do: ""}
      data-multiple={if @multiple, do: ""}
      data-required={if @required, do: ""}
      data-status={@context.status}
      phx-value-name={@name}
      phx-value-server-status={@context.status}
      phx-value-server-invalid={to_string(@context.invalid)}
      disabled={@disabled}
      hidden={!@context.active}
      inert={!@context.active}
      tabindex="-1"
      aria-invalid={if @context.invalid, do: "true"}
      aria-keyshortcuts={@keys}
      class={classes([~S|flex min-w-0 flex-col gap-4 border-0 p-0 outline-none|, @class])}
      {@rest}
    >
      {render_slot(@inner_block, @context)}
    </fieldset>
    """
  end

  defp item_keyshortcuts(false, _context, _status), do: nil

  defp item_keyshortcuts(true, context, status) do
    [
      "Meta+Enter Control+Enter",
      if(!context.first, do: "ArrowLeft"),
      if(!context.last and status != "unanswered", do: "ArrowRight")
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.join(" ")
  end

  attr :class, :string, default: nil

  attr :rest, :global,
    include:
      ~w(aria-label aria-describedby aria-keyshortcuts role tabindex form name placeholder autocomplete min max step minlength maxlength pattern readonly type value disabled required)

  slot :inner_block

  def questionnaire_title(assigns) do
    ~H"""
    <legend
      data-slot="questionnaire-title"
      class={
        classes([
          ~S|cn-font-heading text-base leading-snug font-medium text-pretty [&:not(:has(~[data-slot=questionnaire-description]))]:mb-4|,
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </legend>
    """
  end

  attr :id, :string, required: true
  attr :class, :string, default: nil

  attr :rest, :global,
    include:
      ~w(aria-label aria-describedby aria-keyshortcuts role tabindex form name placeholder autocomplete min max step minlength maxlength pattern readonly type value disabled required)

  slot :inner_block

  def questionnaire_description(assigns) do
    ~H"""
    <p
      id={@id}
      data-slot="questionnaire-description"
      class={classes([~S|text-sm text-pretty text-muted-foreground|, @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </p>
    """
  end

  attr :context, :map, required: true
  attr :class, :string, default: nil

  attr :rest, :global,
    include:
      ~w(aria-label aria-describedby aria-keyshortcuts role tabindex form name placeholder autocomplete min max step minlength maxlength pattern readonly type value disabled required)

  slot :inner_block

  def questionnaire_choices(assigns) do
    ~H"""
    <div
      data-slot="questionnaire-choices"
      data-shortcuts={@context.shortcuts}
      class={classes([~S|group/questionnaire-choices grid min-w-0 gap-2|, @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc "Native radio/checkbox answer, with stable input identity and caller-supplied choice index for shortcuts."
  attr :context, :map, required: true
  attr :value, :string, required: true
  attr :id, :string, default: nil
  attr :index, :integer, default: 0
  attr :checked, :boolean, default: false
  attr :default_checked, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :class, :string, default: nil

  attr :rest, :global,
    include:
      ~w(aria-label aria-describedby aria-keyshortcuts role tabindex form name placeholder autocomplete min max step minlength maxlength pattern readonly type value disabled required)

  slot :inner_block

  def questionnaire_choice(assigns) do
    disabled = assigns.disabled or assigns.context.disabled
    shortcut = choice_shortcut(assigns.context.shortcuts, assigns.index, disabled)
    type = if assigns.context.multiple, do: "checkbox", else: "radio"
    id = assigns.id || "radix-#{assigns.context.id}-#{assigns.context.name}-#{assigns.value}"

    keys =
      Enum.join(
        Enum.reject([shortcut, if(!disabled and assigns.checked, do: "Enter")], &is_nil/1),
        " "
      )

    assigns =
      assign(assigns,
        disabled: disabled,
        shortcut: shortcut,
        type: type,
        input_id: id,
        keys: if(keys != "", do: keys)
      )

    ~H"""
    <label
      data-slot="questionnaire-choice"
      data-checked={if @checked, do: ""}
      data-unchecked={if !@checked, do: ""}
      data-disabled={if @disabled, do: ""}
      data-invalid={if @context.invalid, do: ""}
      data-shortcut={@shortcut}
      data-type={@type}
      class={
        classes([
          ~S|group/questionnaire-choice relative flex min-h-11 cursor-pointer items-start gap-2.5 rounded-lg border border-input bg-transparent px-3 py-2.5 text-start text-sm transition-colors outline-none select-none hover:bg-muted/50 has-[>input:focus-visible]:border-ring has-[>input:focus-visible]:ring-3 has-[>input:focus-visible]:ring-ring/50 data-invalid:border-destructive dark:bg-input/20 data-checked:border-primary/40 data-checked:bg-muted dark:data-checked:bg-muted data-disabled:pointer-events-none data-disabled:cursor-not-allowed data-disabled:opacity-50|,
          @class
        ])
      }
      {@rest}
    >
      <input
        id={@input_id}
        data-slot="questionnaire-choice-input"
        data-checked={if @checked, do: ""}
        data-unchecked={if !@checked, do: ""}
        data-disabled={if @disabled, do: ""}
        data-invalid={if @context.invalid, do: ""}
        data-shortcut={@shortcut}
        data-type={@type}
        class="absolute inset-0 z-10 size-full cursor-pointer opacity-0"
        aria-invalid={if @context.invalid, do: "true"}
        aria-keyshortcuts={@keys}
        checked={@checked}
        disabled={@disabled}
        name={if @context.status != "skipped", do: @context.name}
        required={@context.required and not @context.multiple}
        type={@type}
        value={@value}
        phx-value-default-checked={to_string(@default_checked)}
      />
      <span
        aria-hidden="true"
        data-slot="questionnaire-choice-indicator"
        class="pointer-events-none relative flex size-4 shrink-0 translate-y-[--spacing(0.45)] items-center justify-center rounded-[4px] border border-input group-has-data-[slot=questionnaire-choice-description]/questionnaire-choice:translate-y-0.5 group-data-[type=radio]/questionnaire-choice:rounded-full group-data-checked/questionnaire-choice:border-primary group-data-checked/questionnaire-choice:bg-primary group-data-checked/questionnaire-choice:text-primary-foreground dark:bg-input/30 dark:group-data-checked/questionnaire-choice:bg-primary"
      >
        <span
          data-slot="questionnaire-choice-indicator-dot"
          class="hidden size-2 rounded-full bg-primary-foreground group-data-[type=checkbox]/questionnaire-choice:hidden group-data-checked/questionnaire-choice:block"
        ></span>
        <Icon.icon
          name="check"
          data-slot="questionnaire-choice-indicator-check"
          class="hidden size-3.5 group-data-[type=radio]/questionnaire-choice:hidden group-data-checked/questionnaire-choice:block"
        />
      </span>
      <span
        data-slot="questionnaire-choice-label"
        class="flex min-w-0 flex-1 flex-col gap-0.5 leading-snug"
      >{render_slot(@inner_block)}</span>
      <span
        data-slot="questionnaire-choice-shortcut"
        data-shortcut={@shortcut}
        aria-hidden="true"
        hidden={is_nil(@shortcut)}
        class="pointer-events-none ms-auto hidden size-5 shrink-0 translate-y-[--spacing(0.45)] items-center justify-center rounded-md border border-input bg-background font-mono text-[0.625rem] leading-none font-medium text-muted-foreground group-has-data-[slot=questionnaire-choice-description]/questionnaire-choice:translate-y-0.5 group-data-[shortcut]/questionnaire-choice:inline-flex"
      >{@shortcut}</span>
    </label>
    """
  end

  defp choice_shortcut("letters", index, false) when index >= 0 and index < 26, do: <<65 + index>>

  defp choice_shortcut("numbers", index, false) when index >= 0 and index < 9,
    do: Integer.to_string(index + 1)

  defp choice_shortcut(_mode, _index, _disabled), do: nil

  attr :class, :string, default: nil

  attr :rest, :global,
    include:
      ~w(aria-label aria-describedby aria-keyshortcuts role tabindex form name placeholder autocomplete min max step minlength maxlength pattern readonly type value disabled required)

  slot :inner_block

  def questionnaire_choice_description(assigns) do
    ~H"""
    <span
      data-slot="questionnaire-choice-description"
      class={classes([~S|text-muted-foreground|, @class])}
      {@rest}
    >{render_slot(@inner_block)}</span>
    """
  end

  attr :context, :map, required: true
  attr :id, :string, default: nil
  attr :value, :any, default: nil
  attr :type, :string, default: "text"
  attr :disabled, :boolean, default: false
  attr :class, :string, default: nil

  attr :rest, :global,
    include:
      ~w(aria-label aria-describedby aria-keyshortcuts role tabindex form name placeholder autocomplete min max step minlength maxlength pattern readonly type value disabled required)

  def questionnaire_input(assigns) do
    filled = not is_nil(assigns.value) and String.trim(to_string(assigns.value)) != ""

    assigns =
      assign(assigns,
        filled: filled,
        disabled: assigns.disabled or assigns.context.disabled,
        input_id: assigns.id || "radix-#{assigns.context.id}-#{assigns.context.name}-input"
      )

    ~H"""
    <div
      data-slot="questionnaire-input-wrapper"
      class="group/questionnaire-input relative w-full min-w-0"
    >
      <input
        id={@input_id}
        data-slot="questionnaire-input"
        data-disabled={if @disabled, do: ""}
        data-filled={if @filled, do: ""}
        data-empty={if !@filled, do: ""}
        data-invalid={if @context.invalid, do: ""}
        aria-invalid={if @context.invalid, do: "true"}
        disabled={@disabled}
        form=""
        type={@type}
        value={@value}
        class={
          classes([
            ~S|h-8 min-h-11 w-full min-w-0 rounded-lg border border-input bg-transparent px-2.5 py-1 text-base transition-[color,box-shadow,background-color] outline-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 disabled:pointer-events-none disabled:cursor-not-allowed disabled:bg-input/50 disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 sm:min-h-0 md:text-sm dark:bg-input/30 dark:disabled:bg-input/80 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 selection:bg-primary selection:text-primary-foreground placeholder:text-muted-foreground|,
            @class
          ])
        }
        {@rest}
      />
    </div>
    """
  end

  attr :context, :map, required: true
  attr :id, :string, required: true
  attr :class, :string, default: nil

  attr :rest, :global,
    include:
      ~w(aria-label aria-describedby aria-keyshortcuts role tabindex form name placeholder autocomplete min max step minlength maxlength pattern readonly type value disabled required)

  slot :inner_block

  def questionnaire_error(assigns) do
    ~H"""
    <p
      id={@id}
      data-slot="questionnaire-error"
      data-invalid={if @context.invalid, do: ""}
      hidden={!@context.invalid}
      role={if @context.invalid, do: "alert"}
      class={classes([~S|mt-2 text-sm text-destructive|, @class])}
      {@rest}
    >
      <%= if @inner_block == [] do %>
        {if @context.required,
          do: "Choose an answer to continue.",
          else: "Choose an answer or skip this question."}
      <% else %>
        {render_slot(@inner_block)}
      <% end %>
    </p>
    """
  end

  attr :class, :string, default: nil

  attr :rest, :global,
    include:
      ~w(aria-label aria-describedby aria-keyshortcuts role tabindex form name placeholder autocomplete min max step minlength maxlength pattern readonly type value disabled required)

  slot :inner_block

  def questionnaire_actions(assigns) do
    ~H"""
    <div
      data-slot="questionnaire-actions"
      class={
        classes([
          ~S|grid min-h-11 w-full grid-cols-[minmax(0,1fr)_auto_auto] items-center gap-2 sm:min-h-8|,
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :string, default: nil

  attr :rest, :global,
    include:
      ~w(aria-label aria-describedby aria-keyshortcuts role tabindex form name placeholder autocomplete min max step minlength maxlength pattern readonly type value disabled required)

  attr :context, :map, required: true
  attr :disabled, :boolean, default: false
  attr :tabindex, :integer, default: nil
  attr :variant, :string, default: "outline"
  attr :size, :string, default: "default"
  slot :inner_block

  def questionnaire_previous(assigns) do
    context = assigns.context
    visible = context.total > 1 and not context.first
    shortcut = if visible and not assigns.disabled and "previous" in ~w(next submit), do: "Enter"
    assigns = assign(assigns, visible: visible, shortcut: shortcut)

    ~H"""
    <button
      data-slot="questionnaire-previous"
      data-disabled={if @disabled, do: ""}
      data-shortcut={@shortcut}
      data-status={@context.status}
      data-visible={if @visible, do: ""}
      data-hidden={if !@visible, do: ""}
      data-size={@size}
      data-variant={@variant}
      aria-hidden={if !@visible, do: "true"}
      aria-keyshortcuts={@shortcut}
      disabled={@disabled}
      hidden={!@visible}
      inert={!@visible}
      tabindex={if @visible, do: @tabindex, else: -1}
      phx-value-tabindex={@tabindex}
      type="button"
      class={
        classes([
          button_classes(@variant, @size),
          "col-start-1 row-start-1 min-h-11 justify-self-start sm:min-h-0",
          @class
        ])
      }
      {@rest}
    >
      <%= if @inner_block == [] do %>
        Previous
      <% else %>
        {render_slot(@inner_block)}
      <% end %>
    </button>
    """
  end

  attr :class, :string, default: nil

  attr :rest, :global,
    include:
      ~w(aria-label aria-describedby aria-keyshortcuts role tabindex form name placeholder autocomplete min max step minlength maxlength pattern readonly type value disabled required)

  attr :context, :map, required: true
  attr :disabled, :boolean, default: false
  attr :tabindex, :integer, default: nil
  attr :variant, :string, default: "outline"
  attr :size, :string, default: "default"
  slot :inner_block

  def questionnaire_skip(assigns) do
    context = assigns.context
    visible = context.required == false
    shortcut = if visible and not assigns.disabled and "skip" in ~w(next submit), do: "Enter"
    assigns = assign(assigns, visible: visible, shortcut: shortcut)

    ~H"""
    <button
      data-slot="questionnaire-skip"
      data-disabled={if @disabled, do: ""}
      data-shortcut={@shortcut}
      data-status={@context.status}
      data-visible={if @visible, do: ""}
      data-hidden={if !@visible, do: ""}
      data-size={@size}
      data-variant={@variant}
      aria-hidden={if !@visible, do: "true"}
      aria-keyshortcuts={@shortcut}
      disabled={@disabled}
      hidden={!@visible}
      inert={!@visible}
      tabindex={if @visible, do: @tabindex, else: -1}
      phx-value-tabindex={@tabindex}
      type="button"
      class={
        classes([
          button_classes(@variant, @size),
          "col-start-2 row-start-1 min-h-11 justify-self-end sm:min-h-0",
          @class
        ])
      }
      {@rest}
    >
      <%= if @inner_block == [] do %>
        Skip
      <% else %>
        {render_slot(@inner_block)}
      <% end %>
    </button>
    """
  end

  attr :class, :string, default: nil

  attr :rest, :global,
    include:
      ~w(aria-label aria-describedby aria-keyshortcuts role tabindex form name placeholder autocomplete min max step minlength maxlength pattern readonly type value disabled required)

  attr :context, :map, required: true
  attr :disabled, :boolean, default: false
  attr :tabindex, :integer, default: nil
  attr :variant, :string, default: "default"
  attr :size, :string, default: "default"
  slot :inner_block

  def questionnaire_next(assigns) do
    context = assigns.context
    visible = context.total > 1 and not context.last
    shortcut = if visible and not assigns.disabled and "next" in ~w(next submit), do: "Enter"
    assigns = assign(assigns, visible: visible, shortcut: shortcut)

    ~H"""
    <button
      data-slot="questionnaire-next"
      data-disabled={if @disabled, do: ""}
      data-shortcut={@shortcut}
      data-status={@context.status}
      data-visible={if @visible, do: ""}
      data-hidden={if !@visible, do: ""}
      data-size={@size}
      data-variant={@variant}
      aria-hidden={if !@visible, do: "true"}
      aria-keyshortcuts={@shortcut}
      disabled={@disabled}
      hidden={!@visible}
      inert={!@visible}
      tabindex={if @visible, do: @tabindex, else: -1}
      phx-value-tabindex={@tabindex}
      type="button"
      class={
        classes([
          button_classes(@variant, @size),
          "col-start-3 row-start-1 min-h-11 justify-self-end sm:min-h-0",
          @class
        ])
      }
      {@rest}
    >
      <%= if @inner_block == [] do %>
        Next
      <% else %>
        {render_slot(@inner_block)}
      <% end %>
    </button>
    """
  end

  attr :class, :string, default: nil

  attr :rest, :global,
    include:
      ~w(aria-label aria-describedby aria-keyshortcuts role tabindex form name placeholder autocomplete min max step minlength maxlength pattern readonly type value disabled required)

  attr :context, :map, required: true
  attr :disabled, :boolean, default: false
  attr :tabindex, :integer, default: nil
  attr :variant, :string, default: "default"
  attr :size, :string, default: "default"
  slot :inner_block

  def questionnaire_submit(assigns) do
    context = assigns.context
    visible = context.total > 0 and context.last
    shortcut = if visible and not assigns.disabled and "submit" in ~w(next submit), do: "Enter"
    assigns = assign(assigns, visible: visible, shortcut: shortcut)

    ~H"""
    <button
      data-slot="questionnaire-submit"
      data-disabled={if @disabled, do: ""}
      data-shortcut={@shortcut}
      data-status={@context.status}
      data-visible={if @visible, do: ""}
      data-hidden={if !@visible, do: ""}
      data-size={@size}
      data-variant={@variant}
      aria-hidden={if !@visible, do: "true"}
      aria-keyshortcuts={@shortcut}
      disabled={@disabled}
      hidden={!@visible}
      inert={!@visible}
      tabindex={if @visible, do: @tabindex, else: -1}
      phx-value-tabindex={@tabindex}
      type="submit"
      class={
        classes([
          button_classes(@variant, @size),
          "col-start-3 row-start-1 min-h-11 justify-self-end sm:min-h-0",
          @class
        ])
      }
      {@rest}
    >
      <%= if @inner_block == [] do %>
        Submit
      <% else %>
        {render_slot(@inner_block)}
      <% end %>
    </button>
    """
  end

  @button_classes %{
    {"default", "default"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center rounded-lg border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 bg-primary text-primary-foreground hover:bg-primary/80 h-8 gap-1.5 px-2.5 has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2|,
    {"default", "xs"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 bg-primary text-primary-foreground hover:bg-primary/80 h-6 gap-1 rounded-[min(var(--radius-md),10px)] px-2 text-xs in-data-[slot=button-group]:rounded-lg has-data-[icon=inline-end]:pr-1.5 has-data-[icon=inline-start]:pl-1.5 [&_svg:not([class*='size-'])]:size-3|,
    {"default", "sm"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 bg-primary text-primary-foreground hover:bg-primary/80 h-7 gap-1 rounded-[min(var(--radius-md),12px)] px-2.5 text-[0.8rem] in-data-[slot=button-group]:rounded-lg has-data-[icon=inline-end]:pr-1.5 has-data-[icon=inline-start]:pl-1.5 [&_svg:not([class*='size-'])]:size-3.5|,
    {"default", "lg"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center rounded-lg border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 bg-primary text-primary-foreground hover:bg-primary/80 h-9 gap-1.5 px-2.5 has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2|,
    {"default", "icon"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center rounded-lg border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 bg-primary text-primary-foreground hover:bg-primary/80 size-8|,
    {"default", "icon-xs"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 bg-primary text-primary-foreground hover:bg-primary/80 size-6 rounded-[min(var(--radius-md),10px)] in-data-[slot=button-group]:rounded-lg [&_svg:not([class*='size-'])]:size-3|,
    {"default", "icon-sm"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 bg-primary text-primary-foreground hover:bg-primary/80 size-7 rounded-[min(var(--radius-md),12px)] in-data-[slot=button-group]:rounded-lg|,
    {"default", "icon-lg"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center rounded-lg border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 bg-primary text-primary-foreground hover:bg-primary/80 size-9|,
    {"outline", "default"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center rounded-lg border bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 border-border bg-background hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:border-input dark:bg-input/30 dark:hover:bg-input/50 h-8 gap-1.5 px-2.5 has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2|,
    {"outline", "xs"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center border bg-clip-padding font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 border-border bg-background hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:border-input dark:bg-input/30 dark:hover:bg-input/50 h-6 gap-1 rounded-[min(var(--radius-md),10px)] px-2 text-xs in-data-[slot=button-group]:rounded-lg has-data-[icon=inline-end]:pr-1.5 has-data-[icon=inline-start]:pl-1.5 [&_svg:not([class*='size-'])]:size-3|,
    {"outline", "sm"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center border bg-clip-padding font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 border-border bg-background hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:border-input dark:bg-input/30 dark:hover:bg-input/50 h-7 gap-1 rounded-[min(var(--radius-md),12px)] px-2.5 text-[0.8rem] in-data-[slot=button-group]:rounded-lg has-data-[icon=inline-end]:pr-1.5 has-data-[icon=inline-start]:pl-1.5 [&_svg:not([class*='size-'])]:size-3.5|,
    {"outline", "lg"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center rounded-lg border bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 border-border bg-background hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:border-input dark:bg-input/30 dark:hover:bg-input/50 h-9 gap-1.5 px-2.5 has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2|,
    {"outline", "icon"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center rounded-lg border bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 border-border bg-background hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:border-input dark:bg-input/30 dark:hover:bg-input/50 size-8|,
    {"outline", "icon-xs"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center border bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 border-border bg-background hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:border-input dark:bg-input/30 dark:hover:bg-input/50 size-6 rounded-[min(var(--radius-md),10px)] in-data-[slot=button-group]:rounded-lg [&_svg:not([class*='size-'])]:size-3|,
    {"outline", "icon-sm"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center border bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 border-border bg-background hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:border-input dark:bg-input/30 dark:hover:bg-input/50 size-7 rounded-[min(var(--radius-md),12px)] in-data-[slot=button-group]:rounded-lg|,
    {"outline", "icon-lg"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center rounded-lg border bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 border-border bg-background hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:border-input dark:bg-input/30 dark:hover:bg-input/50 size-9|,
    {"secondary", "default"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center rounded-lg border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 bg-secondary text-secondary-foreground hover:bg-[color-mix(in_oklch,var(--secondary),var(--foreground)_5%)] aria-expanded:bg-secondary aria-expanded:text-secondary-foreground h-8 gap-1.5 px-2.5 has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2|,
    {"secondary", "xs"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 bg-secondary text-secondary-foreground hover:bg-[color-mix(in_oklch,var(--secondary),var(--foreground)_5%)] aria-expanded:bg-secondary aria-expanded:text-secondary-foreground h-6 gap-1 rounded-[min(var(--radius-md),10px)] px-2 text-xs in-data-[slot=button-group]:rounded-lg has-data-[icon=inline-end]:pr-1.5 has-data-[icon=inline-start]:pl-1.5 [&_svg:not([class*='size-'])]:size-3|,
    {"secondary", "sm"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 bg-secondary text-secondary-foreground hover:bg-[color-mix(in_oklch,var(--secondary),var(--foreground)_5%)] aria-expanded:bg-secondary aria-expanded:text-secondary-foreground h-7 gap-1 rounded-[min(var(--radius-md),12px)] px-2.5 text-[0.8rem] in-data-[slot=button-group]:rounded-lg has-data-[icon=inline-end]:pr-1.5 has-data-[icon=inline-start]:pl-1.5 [&_svg:not([class*='size-'])]:size-3.5|,
    {"secondary", "lg"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center rounded-lg border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 bg-secondary text-secondary-foreground hover:bg-[color-mix(in_oklch,var(--secondary),var(--foreground)_5%)] aria-expanded:bg-secondary aria-expanded:text-secondary-foreground h-9 gap-1.5 px-2.5 has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2|,
    {"secondary", "icon"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center rounded-lg border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 bg-secondary text-secondary-foreground hover:bg-[color-mix(in_oklch,var(--secondary),var(--foreground)_5%)] aria-expanded:bg-secondary aria-expanded:text-secondary-foreground size-8|,
    {"secondary", "icon-xs"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 bg-secondary text-secondary-foreground hover:bg-[color-mix(in_oklch,var(--secondary),var(--foreground)_5%)] aria-expanded:bg-secondary aria-expanded:text-secondary-foreground size-6 rounded-[min(var(--radius-md),10px)] in-data-[slot=button-group]:rounded-lg [&_svg:not([class*='size-'])]:size-3|,
    {"secondary", "icon-sm"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 bg-secondary text-secondary-foreground hover:bg-[color-mix(in_oklch,var(--secondary),var(--foreground)_5%)] aria-expanded:bg-secondary aria-expanded:text-secondary-foreground size-7 rounded-[min(var(--radius-md),12px)] in-data-[slot=button-group]:rounded-lg|,
    {"secondary", "icon-lg"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center rounded-lg border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 bg-secondary text-secondary-foreground hover:bg-[color-mix(in_oklch,var(--secondary),var(--foreground)_5%)] aria-expanded:bg-secondary aria-expanded:text-secondary-foreground size-9|,
    {"ghost", "default"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center rounded-lg border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:hover:bg-muted/50 h-8 gap-1.5 px-2.5 has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2|,
    {"ghost", "xs"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:hover:bg-muted/50 h-6 gap-1 rounded-[min(var(--radius-md),10px)] px-2 text-xs in-data-[slot=button-group]:rounded-lg has-data-[icon=inline-end]:pr-1.5 has-data-[icon=inline-start]:pl-1.5 [&_svg:not([class*='size-'])]:size-3|,
    {"ghost", "sm"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:hover:bg-muted/50 h-7 gap-1 rounded-[min(var(--radius-md),12px)] px-2.5 text-[0.8rem] in-data-[slot=button-group]:rounded-lg has-data-[icon=inline-end]:pr-1.5 has-data-[icon=inline-start]:pl-1.5 [&_svg:not([class*='size-'])]:size-3.5|,
    {"ghost", "lg"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center rounded-lg border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:hover:bg-muted/50 h-9 gap-1.5 px-2.5 has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2|,
    {"ghost", "icon"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center rounded-lg border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:hover:bg-muted/50 size-8|,
    {"ghost", "icon-xs"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:hover:bg-muted/50 size-6 rounded-[min(var(--radius-md),10px)] in-data-[slot=button-group]:rounded-lg [&_svg:not([class*='size-'])]:size-3|,
    {"ghost", "icon-sm"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:hover:bg-muted/50 size-7 rounded-[min(var(--radius-md),12px)] in-data-[slot=button-group]:rounded-lg|,
    {"ghost", "icon-lg"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center rounded-lg border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:hover:bg-muted/50 size-9|,
    {"destructive", "default"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center rounded-lg border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:ring-3 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 bg-destructive/10 text-destructive hover:bg-destructive/20 focus-visible:border-destructive/40 focus-visible:ring-destructive/20 dark:bg-destructive/20 dark:hover:bg-destructive/30 dark:focus-visible:ring-destructive/40 h-8 gap-1.5 px-2.5 has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2|,
    {"destructive", "xs"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:ring-3 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 bg-destructive/10 text-destructive hover:bg-destructive/20 focus-visible:border-destructive/40 focus-visible:ring-destructive/20 dark:bg-destructive/20 dark:hover:bg-destructive/30 dark:focus-visible:ring-destructive/40 h-6 gap-1 rounded-[min(var(--radius-md),10px)] px-2 text-xs in-data-[slot=button-group]:rounded-lg has-data-[icon=inline-end]:pr-1.5 has-data-[icon=inline-start]:pl-1.5 [&_svg:not([class*='size-'])]:size-3|,
    {"destructive", "sm"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:ring-3 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 bg-destructive/10 text-destructive hover:bg-destructive/20 focus-visible:border-destructive/40 focus-visible:ring-destructive/20 dark:bg-destructive/20 dark:hover:bg-destructive/30 dark:focus-visible:ring-destructive/40 h-7 gap-1 rounded-[min(var(--radius-md),12px)] px-2.5 text-[0.8rem] in-data-[slot=button-group]:rounded-lg has-data-[icon=inline-end]:pr-1.5 has-data-[icon=inline-start]:pl-1.5 [&_svg:not([class*='size-'])]:size-3.5|,
    {"destructive", "lg"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center rounded-lg border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:ring-3 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 bg-destructive/10 text-destructive hover:bg-destructive/20 focus-visible:border-destructive/40 focus-visible:ring-destructive/20 dark:bg-destructive/20 dark:hover:bg-destructive/30 dark:focus-visible:ring-destructive/40 h-9 gap-1.5 px-2.5 has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2|,
    {"destructive", "icon"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center rounded-lg border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:ring-3 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 bg-destructive/10 text-destructive hover:bg-destructive/20 focus-visible:border-destructive/40 focus-visible:ring-destructive/20 dark:bg-destructive/20 dark:hover:bg-destructive/30 dark:focus-visible:ring-destructive/40 size-8|,
    {"destructive", "icon-xs"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:ring-3 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 bg-destructive/10 text-destructive hover:bg-destructive/20 focus-visible:border-destructive/40 focus-visible:ring-destructive/20 dark:bg-destructive/20 dark:hover:bg-destructive/30 dark:focus-visible:ring-destructive/40 size-6 rounded-[min(var(--radius-md),10px)] in-data-[slot=button-group]:rounded-lg [&_svg:not([class*='size-'])]:size-3|,
    {"destructive", "icon-sm"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:ring-3 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 bg-destructive/10 text-destructive hover:bg-destructive/20 focus-visible:border-destructive/40 focus-visible:ring-destructive/20 dark:bg-destructive/20 dark:hover:bg-destructive/30 dark:focus-visible:ring-destructive/40 size-7 rounded-[min(var(--radius-md),12px)] in-data-[slot=button-group]:rounded-lg|,
    {"destructive", "icon-lg"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center rounded-lg border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:ring-3 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 bg-destructive/10 text-destructive hover:bg-destructive/20 focus-visible:border-destructive/40 focus-visible:ring-destructive/20 dark:bg-destructive/20 dark:hover:bg-destructive/30 dark:focus-visible:ring-destructive/40 size-9|,
    {"link", "default"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center rounded-lg border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 text-primary underline-offset-4 hover:underline h-8 gap-1.5 px-2.5 has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2|,
    {"link", "xs"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 text-primary underline-offset-4 hover:underline h-6 gap-1 rounded-[min(var(--radius-md),10px)] px-2 text-xs in-data-[slot=button-group]:rounded-lg has-data-[icon=inline-end]:pr-1.5 has-data-[icon=inline-start]:pl-1.5 [&_svg:not([class*='size-'])]:size-3|,
    {"link", "sm"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 text-primary underline-offset-4 hover:underline h-7 gap-1 rounded-[min(var(--radius-md),12px)] px-2.5 text-[0.8rem] in-data-[slot=button-group]:rounded-lg has-data-[icon=inline-end]:pr-1.5 has-data-[icon=inline-start]:pl-1.5 [&_svg:not([class*='size-'])]:size-3.5|,
    {"link", "lg"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center rounded-lg border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 text-primary underline-offset-4 hover:underline h-9 gap-1.5 px-2.5 has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2|,
    {"link", "icon"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center rounded-lg border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 text-primary underline-offset-4 hover:underline size-8|,
    {"link", "icon-xs"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 text-primary underline-offset-4 hover:underline size-6 rounded-[min(var(--radius-md),10px)] in-data-[slot=button-group]:rounded-lg [&_svg:not([class*='size-'])]:size-3|,
    {"link", "icon-sm"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 text-primary underline-offset-4 hover:underline size-7 rounded-[min(var(--radius-md),12px)] in-data-[slot=button-group]:rounded-lg|,
    {"link", "icon-lg"} =>
      ~S|group/button inline-flex shrink-0 items-center justify-center rounded-lg border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 text-primary underline-offset-4 hover:underline size-9|
  }

  defp button_classes(variant, size), do: Map.fetch!(@button_classes, {variant, size})
end
