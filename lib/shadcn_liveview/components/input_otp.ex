defmodule ShadcnLiveview.Components.InputOtp do
  @moduledoc "A single native OTP input with slotted visual cells. Root :let passes the value to each indexed slot. Native name, form, required, disabled, pattern and autocomplete semantics are retained. The colocated hook manages focus, character selection, paste, fake carets and completion. Declared minlength remains enforced through the native Constraint Validation API after LiveView value patches clear the browser user-edit flag; caller-owned custom validity is preserved. on_change/on_complete events receive id and value and route to the nearest phx-target ancestor, or the owning LiveView when absent. Completion waits for the final change acknowledgement before sending on_complete; paste_transform may be strip-separators. Without JavaScript the noscript CSS exposes the real input. With JavaScript the hook restores its adjacent noscript to text after fragment patches, preserving the browser scripting-enabled parsing invariant."
  use Phoenix.Component
  import ShadcnLiveview.Helpers
  alias ShadcnLiveview.Components.Icon

  @no_script_css "\n[data-input-otp] {\n  --nojs-bg: white !important;\n  --nojs-fg: black !important;\n\n  background-color: var(--nojs-bg) !important;\n  color: var(--nojs-fg) !important;\n  caret-color: var(--nojs-fg) !important;\n  letter-spacing: .25em !important;\n  text-align: center !important;\n  border: 1px solid var(--nojs-fg) !important;\n  border-radius: 4px !important;\n  width: 100% !important;\n}\n@media (prefers-color-scheme: dark) {\n  [data-input-otp] {\n    --nojs-bg: black !important;\n    --nojs-fg: white !important;\n  }\n}"
  @doc "Render indexed cells with :let and context; id belongs to the native input."
  attr :id, :string,
    required: true,
    doc:
      "Stable, unique DOM id, constant across renders; the colocated hook and event payloads use it."

  attr :max_length, :integer, required: true
  attr :value, :string, default: ""
  attr :disabled, :boolean, default: false
  attr :pattern, :string, default: nil
  attr :placeholder, :string, default: nil
  attr :input_mode, :string, default: "numeric"
  attr :text_align, :string, default: "left"
  attr :paste_transform, :string, default: nil, values: [nil, "strip-separators"]

  attr :on_change, :string,
    default: nil,
    doc:
      "LiveView event name pushed on change; the payload is described in the module docs. `nil` pushes no event."

  attr :on_complete, :string,
    default: nil,
    doc:
      "LiveView event name pushed on complete; the payload is described in the module docs. `nil` pushes no event."

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :container_class, :string, default: nil
  attr :no_script_css, :string, default: @no_script_css

  attr :rest, :global,
    include:
      ~w(type name form required readonly autocomplete autofocus minlength title aria-label aria-describedby aria-invalid)

  slot :inner_block, required: true

  def input_otp(assigns) do
    assigns = assign(assigns, :context, %{value: assigns.value, max_length: assigns.max_length})

    ~H"""
    <noscript :if={@no_script_css}>{Phoenix.HTML.raw(["<style>", @no_script_css, "</style>"])}</noscript>
    <div
      data-input-otp-container="true"
      translate="no"
      style={"position:relative;cursor:" <> if(@disabled, do: "default", else: "text") <> ";user-select:none;-webkit-user-select:none;pointer-events:none"}
      class={classes(["cn-input-otp flex items-center has-disabled:opacity-50", @container_class])}
    >
      {render_slot(@inner_block, @context)}
      <div style="position:absolute;inset:0;pointer-events:none">
        <input
          id={@id}
          autocomplete="one-time-code"
          data-slot="input-otp"
          spellcheck="false"
          class={classes(["disabled:cursor-not-allowed", @class])}
          data-input-otp="true"
          data-input-otp-placeholder-shown={@value == "" && "true"}
          inputmode={@input_mode}
          pattern={@pattern}
          aria-placeholder={@placeholder}
          disabled={@disabled}
          maxlength={@max_length}
          value={@value}
          style={"position:absolute;inset:0;width:100%;height:100%;display:flex;text-align:" <> @text_align <> ";opacity:1;color:transparent;pointer-events:all;background:transparent;caret-color:transparent;border:0 solid transparent;outline:0 solid transparent;box-shadow:none;line-height:1;letter-spacing:-.5em;font-size:var(--root-height, 16px);font-family:monospace;font-variant-numeric:tabular-nums"}
          phx-hook=".InputOTP"
          phx-value-value={@value}
          phx-value-transform={@paste_transform}
          phx-value-change={@on_change}
          phx-value-complete={@on_complete}
          {@rest}
        />
      </div>
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".InputOTP">
        export default {
      sendEvent(event, payload, onReply) {
      const target = this.el.closest('[phx-target]')?.getAttribute("phx-target");
      const push = target
        ? this.pushEventTo(target, event, payload).then(results => {
            const failed = results.find(result => result.status === "rejected");
            if (failed) throw failed.reason;
            return results[0]?.value.reply;
          })
        : this.pushEvent(event, payload);
      push.catch(() => {});
      if (onReply) push.then(onReply, () => {});
      return push;
      },
      mounted() {
      this.container = this.el.closest("[data-input-otp-container]"); this.listeners = []; this.lastValue = this.el.value;
      this.serverValue = this.el.getAttribute("phx-value-value") || ""; this.pendingValues = [];
      this.listen = (node, type, handler) => { node.addEventListener(type, handler); this.listeners.push([node, type, handler]); };
      this.listen(document, "phx:update", () => this.repairNoScript());
      this.repairNoScript();
      this.listen(this.el, "focus", () => { const end = this.el.value.length; this.el.setSelectionRange(Math.min(end, this.el.maxLength - 1), end); this.paint(); });
      this.listen(this.el, "blur", () => this.paint());
      this.listen(this.el, "input", e => {
        if (this.lengthError && this.el.validationMessage === this.lengthError) this.el.setCustomValidity("");
        const nativeMessage = e.isTrusted && this.el.validity.tooShort ? this.el.validationMessage : "";
        this.accept(nativeMessage);
      });
      this.listen(this.el, "paste", e => {
        if (this.el.disabled || this.el.readOnly) return;
        let pasted = e.clipboardData.getData("text/plain");
        if (this.el.getAttribute("phx-value-transform") === "strip-separators") pasted = pasted.replace(/[\s-]/g, "");
        e.preventDefault();
        const start = this.el.selectionStart ?? this.el.value.length;
        const end = this.el.selectionEnd ?? start;
        this.el.value = (this.el.value.slice(0, start) + pasted + this.el.value.slice(end)).slice(0, this.el.maxLength);
        const cursor = Math.min(start + pasted.length, this.el.value.length);
        this.el.setSelectionRange(Math.min(cursor, this.el.maxLength - 1), cursor);
        this.el.dispatchEvent(new Event("input", {bubbles: true}));
      });
      this.listen(document, "selectionchange", () => {
        if (document.activeElement !== this.el) return;
        const start = this.el.selectionStart, end = this.el.selectionEnd;
        if (start === end && this.el.value.length && start < this.el.value.length) this.el.setSelectionRange(start, start + 1);
        else if (start === end && start === this.el.maxLength) this.el.setSelectionRange(start - 1, start);
        this.paint();
      });
      if (this.el.form) this.listen(this.el.form, "reset", () => queueMicrotask(() => { this.lastValue = this.el.value; this.validateLength(); this.paint(); }));
      this.resize = new ResizeObserver(() => this.container.style.setProperty("--root-height", this.el.clientHeight + "px"));
      this.resize.observe(this.el); this.validateLength(); this.paint();
      },
      repairNoScript() {
      const fallback = this.container.previousElementSibling;
      if (fallback?.localName === "noscript" && fallback.firstElementChild) fallback.textContent = fallback.innerHTML;
      },
      validateLength(nativeMessage = "") {
      if (this.el.validity.customError && this.el.validationMessage !== this.lengthError) { this.lengthError = ""; return; }
      const value = this.el.value, minimum = this.el.minLength;
      if (nativeMessage) { this.nativeLengthMessage = nativeMessage; this.nativeLengthValue = value; }
      const short = value !== "" && minimum > 0 && value.length < minimum;
      const message = short ? nativeMessage || (this.nativeLengthValue === value && this.nativeLengthMessage) || "Please enter at least " + minimum + " characters." : "";
      if (this.el.validationMessage !== message || !this.el.validity.customError) this.el.setCustomValidity(message);
      this.lengthError = message;
      },
      accept(nativeMessage = "") {
      const previous = this.lastValue;
      const value = this.el.value.slice(0, this.el.maxLength);
      const pattern = this.el.pattern;
      if (value && pattern && !new RegExp(pattern).test(value)) { this.el.value = previous; this.validateLength(); this.paint(); return; }
      if (this.el.value !== value) this.el.value = value;
      this.lastValue = value; this.validateLength(nativeMessage); this.paint();
      if (value === previous) return;
      const detail = {id: this.el.id, value};
      this.el.dispatchEvent(new CustomEvent("shadcn:otp-change", {bubbles: true, detail}));
      const event = this.el.getAttribute("phx-value-change");
      const completed = value.length === this.el.maxLength && previous.length < this.el.maxLength;
      const complete = completed && this.el.getAttribute("phx-value-complete");
      if (event) {
        this.pendingValues.push(value);
        // Complete only after the change reply releases LiveView's input lock.
        // Typed text stays local like a native input; a failed push only drops its acknowledgement.
        this.sendEvent(event, detail, () => { if (complete) this.sendEvent(complete, detail); }).catch(() => {
          const index = this.pendingValues.indexOf(value); if (index >= 0) this.pendingValues.splice(index, 1);
        });
      }
      if (completed) {
        this.el.dispatchEvent(new CustomEvent("shadcn:otp-complete", {bubbles: true, detail}));
        if (!event && complete) this.sendEvent(complete, detail);
      }
      },
      paint() {
      const focused = document.activeElement === this.el;
      const start = this.el.selectionStart ?? 0, end = this.el.selectionEnd ?? start;
      this.container.querySelectorAll("[data-slot=input-otp-slot]").forEach(slot => {
        const index = Number(slot.getAttribute("phx-value-index"));
        const char = this.el.value[index] || "";
        const active = focused && !this.el.disabled && (start === end ? index === start : index >= start && index < end);
        slot.setAttribute("data-active", String(active)); slot.replaceChildren(document.createTextNode(char));
        if (active && !char) {
          const caret = document.createElement("div"); caret.className = "pointer-events-none absolute inset-0 flex items-center justify-center";
          const bar = document.createElement("div"); bar.className = "h-4 w-px animate-caret-blink bg-foreground duration-1000"; caret.append(bar); slot.append(caret);
        }
      });
      if (!this.el.value) this.el.setAttribute("data-input-otp-placeholder-shown", "true"); else this.el.removeAttribute("data-input-otp-placeholder-shown");
      if (focused) { this.el.setAttribute("data-input-otp-mss", start); this.el.setAttribute("data-input-otp-mse", end); }
      else { this.el.removeAttribute("data-input-otp-mss"); this.el.removeAttribute("data-input-otp-mse"); }
      },
      updated() {
      const serverValue = this.el.getAttribute("phx-value-value") || "";
      if (serverValue !== this.serverValue) {
        const acknowledged = this.pendingValues.lastIndexOf(serverValue);
        if (acknowledged >= 0) this.pendingValues.splice(0, acknowledged + 1);
        else { this.pendingValues = []; if (this.el.value !== serverValue) this.el.value = serverValue; }
        if (!this.pendingValues.length && this.el.value !== serverValue) this.el.value = serverValue;
      }
      this.serverValue = serverValue; this.lastValue = this.el.value; this.validateLength(); this.paint();
      },
      destroyed() { this.listeners.forEach(([node, type, handler]) => node.removeEventListener(type, handler)); this.resize.disconnect(); }
      }
    </script>
    """
  end

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global
  slot :inner_block, required: true

  def input_otp_group(assigns) do
    ~H"""
    <div
      data-slot="input-otp-group"
      class={
        classes([
          "flex items-center rounded-lg has-aria-invalid:border-destructive has-aria-invalid:ring-3 has-aria-invalid:ring-destructive/20 dark:has-aria-invalid:ring-destructive/40",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :context, :map, required: true
  attr :index, :integer, required: true

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global

  def input_otp_slot(assigns) do
    ~H"""
    <div
      data-slot="input-otp-slot"
      data-active="false"
      class={
        classes([
          "relative flex size-8 items-center justify-center border-y border-r border-input text-sm transition-all outline-none first:rounded-l-lg first:border-l last:rounded-r-lg aria-invalid:border-destructive data-[active=true]:z-10 data-[active=true]:border-ring data-[active=true]:ring-3 data-[active=true]:ring-ring/50 data-[active=true]:aria-invalid:border-destructive data-[active=true]:aria-invalid:ring-destructive/20 dark:bg-input/30 dark:data-[active=true]:aria-invalid:ring-destructive/40",
          @class
        ])
      }
      phx-value-index={@index}
      {@rest}
    >
      {String.at(@context.value, @index)}
    </div>
    """
  end

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global

  def input_otp_separator(assigns) do
    ~H"""
    <div
      data-slot="input-otp-separator"
      class={classes(["flex items-center [&_svg:not([class*='size-'])]:size-4", @class])}
      role="separator"
      {@rest}
    >
      <Icon.icon name="minus" />
    </div>
    """
  end
end
