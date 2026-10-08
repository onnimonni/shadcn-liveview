defmodule ShadcnLiveview.Components.Switch do
  @moduledoc """
  Native-form switch with a stable caller ID. checked controls server state;
  default_checked supplies the initial uncontrolled state. Form reset restores
  the mounted initial state, even after server patches. on_change receives
  %{id => id, value => boolean}. Labels target the button ID.
  Inline layout is preserved when placed beside other native controls.
  Space and Enter use native button activation.
  """
  use Phoenix.Component
  import ShadcnLiveview.Helpers, only: [classes: 1]

  attr :id, :string, required: true
  attr :checked, :any, default: nil
  attr :default_checked, :any, default: nil
  attr :name, :string, default: nil
  attr :value, :string, default: "on"
  attr :form, :string, default: nil
  attr :disabled, :boolean, default: false
  attr :required, :boolean, default: false
  attr :on_change, :string, default: nil
  attr :size, :string, values: ~w(default sm), default: "default"
  attr :class, :string, default: nil
  attr :rest, :global

  def switch(assigns) do
    checked = if is_nil(assigns.checked), do: assigns.default_checked, else: assigns.checked
    assigns = assign(assigns, state: state(checked), initial: state(checked))

    ~H"""
    <button
      id={@id}
      type="button"
      role="switch"
      aria-checked={if @state == "indeterminate", do: "mixed", else: to_string(@state == "checked")}
      aria-required={if @required, do: "true"}
      data-state={@state}
      data-disabled={if @disabled, do: ""}
      disabled={@disabled}
      value={@value}
      data-slot="switch"
      data-size={@size}
      class={
        classes([
          "peer group/switch relative inline-flex shrink-0 items-center rounded-full border border-transparent transition-all outline-none group-has-[:focus-visible]/field-label:border-transparent group-has-[:focus-visible]/field-label:ring-0 after:absolute after:-inset-x-3 after:-inset-y-2 focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 data-[size=default]:h-[18.4px] data-[size=default]:w-[32px] data-[size=sm]:h-[14px] data-[size=sm]:w-[24px] dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 data-checked:bg-primary data-unchecked:bg-input dark:data-unchecked:bg-input/80 data-disabled:cursor-not-allowed data-disabled:opacity-50",
          @class
        ])
      }
      phx-hook=".BinaryControl"
      phx-value-change={@on_change}
      phx-value-state={@state}
      phx-value-initial={@initial}
      {@rest}
    >
      <span
        data-state={@state}
        data-disabled={if @disabled, do: ""}
        data-slot="switch-thumb"
        class="pointer-events-none block rounded-full bg-background ring-0 transition-transform group-data-[size=default]/switch:size-4 group-data-[size=sm]/switch:size-3 group-data-[size=default]/switch:data-checked:translate-x-[calc(100%-2px)] group-data-[size=sm]/switch:data-checked:translate-x-[calc(100%-2px)] dark:data-checked:bg-primary-foreground group-data-[size=default]/switch:data-unchecked:translate-x-0 group-data-[size=sm]/switch:data-unchecked:translate-x-0 dark:data-unchecked:bg-foreground"
      />
      <script :type={Phoenix.LiveView.ColocatedHook} name=".BinaryControl">
        export default {
          mounted() {
            this.input = this.el.nextElementSibling;
            this.initial = this.el.getAttribute("phx-value-initial");
            this.click = () => {
              if (this.el.disabled) return;
              this.setState(this.el.getAttribute("data-state") === "checked" ? "unchecked" : "checked", true);
            };
            this.reset = () => { this.resetFrame = requestAnimationFrame(() => this.setState(this.initial, true)); };
            this.invalid = () => this.el.focus();
            this.el.addEventListener("click", this.click);
            this.input.addEventListener("invalid", this.invalid);
            this.updated();
          },
          updated() {
            const input = this.el.nextElementSibling;
            if (input !== this.input) {
              this.input.removeEventListener("invalid", this.invalid);
              input.addEventListener("invalid", this.invalid);
              this.input = input;
            }
            this.serverState = this.el.getAttribute("phx-value-state");
            this.serverChildren = Array.from(this.el.childNodes);
            if (this.form !== this.input.form) {
              if (this.form) this.form.removeEventListener("reset", this.reset);
              this.form = this.input.form;
              if (this.form) this.form.addEventListener("reset", this.reset);
            }
            this.setState(this.serverState, false);
          },
          beforeUpdate() {
            this.el.replaceChildren(...this.serverChildren);
            this.setState(this.serverState, false);
          },
          setState(state, notify) {
            const checked = state === "checked";
            this.el.setAttribute("data-state", state);
            this.el.setAttribute("aria-checked", state === "indeterminate" ? "mixed" : String(checked));
            this.input.checked = checked;
            this.input.indeterminate = state === "indeterminate";
            let child = this.el.firstElementChild;
            if (this.el.getAttribute("role") === "checkbox") {
              if (state === "unchecked") { if (child) child.remove(); }
              else if (!child) {
                child = document.createElement("span");
                child.setAttribute("data-slot", "checkbox-indicator");
                child.className = "grid place-content-center text-current transition-none [&>svg]:size-3.5";
                child.style.pointerEvents = "none";
                const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
                for (const [key, value] of Object.entries({viewBox:"0 0 24 24",width:"24",height:"24",fill:"none",stroke:"currentColor","stroke-width":"2","stroke-linecap":"round","stroke-linejoin":"round","aria-hidden":"true"})) svg.setAttribute(key,value);
                const path = document.createElementNS("http://www.w3.org/2000/svg", "path");
                path.setAttribute("d", "M20 6 9 17l-5-5");
                svg.append(path); child.append(svg); this.el.append(child);
              }
            }
            if (child && state !== "unchecked") child.setAttribute("data-state", state);
            if (child && this.el.getAttribute("role") === "switch") child.setAttribute("data-state", state);
            if (!notify) return;
            this.input.dispatchEvent(new Event("input", {bubbles:true}));
            this.input.dispatchEvent(new Event("change", {bubbles:true}));
            const event = this.el.getAttribute("phx-value-change");
            if (event) this.pushEvent(event, {id:this.el.id, value:checked});
          },
          destroyed() {
            cancelAnimationFrame(this.resetFrame);
            this.el.removeEventListener("click", this.click);
            this.input.removeEventListener("invalid", this.invalid);
            if (this.form) this.form.removeEventListener("reset", this.reset);
          }
        }
      </script>
    </button><input
      type="checkbox"
      aria-hidden="true"
      required={@required}
      disabled={@disabled}
      form={@form}
      tabindex="-1"
      style="position:absolute;pointer-events:none;opacity:0;margin:0;transform:translateX(-100%)"
      name={@name}
      checked={@state == "checked"}
      value={@value}
    />
    """
  end

  defp state(true), do: "checked"
  defp state(_value), do: "unchecked"
end
