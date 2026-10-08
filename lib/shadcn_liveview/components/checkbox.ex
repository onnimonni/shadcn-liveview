defmodule ShadcnLiveview.Components.Checkbox do
  @moduledoc """
  Native-form checkbox with a stable caller ID. checked controls server state;
  default_checked supplies the initial uncontrolled state. Form reset restores
  the mounted initial state, even after server patches. on_change receives
  %{id => id, value => boolean}. Labels target the button ID.
  Inline layout is preserved when placed beside other native controls.
  Use checked="indeterminate" for mixed state; its native input is unchecked.
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
  attr :class, :string, default: nil
  attr :rest, :global

  def checkbox(assigns) do
    checked = if is_nil(assigns.checked), do: assigns.default_checked, else: assigns.checked
    assigns = assign(assigns, state: state(checked), initial: state(checked))

    ~H"""
    <button
      id={@id}
      type="button"
      role="checkbox"
      aria-checked={if @state == "indeterminate", do: "mixed", else: to_string(@state == "checked")}
      aria-required={if @required, do: "true"}
      data-state={@state}
      data-disabled={if @disabled, do: ""}
      disabled={@disabled}
      value={@value}
      data-slot="checkbox"
      class={
        classes([
          "peer relative flex size-4 shrink-0 items-center justify-center rounded-[4px] border border-input transition-colors outline-none group-has-disabled/field:opacity-50 group-has-[:focus-visible]/field-label:ring-0 group-has-[:focus-visible]/field-label:not-data-checked:border-input after:absolute after:-inset-x-3 after:-inset-y-2 focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 disabled:cursor-not-allowed disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 aria-invalid:aria-checked:border-primary dark:bg-input/30 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 data-checked:border-primary data-checked:bg-primary data-checked:text-primary-foreground group-has-[:focus-visible]/field-label:data-checked:border-primary dark:data-checked:bg-primary",
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
        :if={@state != "unchecked"}
        data-state={@state}
        data-disabled={if @disabled, do: ""}
        data-slot="checkbox-indicator"
        class="grid place-content-center text-current transition-none [&>svg]:size-3.5"
        style="pointer-events:none"
      >
        <ShadcnLiveview.Components.Icon.icon name="check" />
      </span>
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

  defp state("indeterminate"), do: "indeterminate"
  defp state(:indeterminate), do: "indeterminate"
  defp state(true), do: "checked"
  defp state(_value), do: "unchecked"
end
