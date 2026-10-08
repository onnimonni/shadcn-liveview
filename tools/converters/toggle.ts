import { cn } from "cn"
import type { ComponentSpec } from "../generate"

export function generateComponent(spec: ComponentSpec): string | undefined {
  if (spec.name !== "toggle") return undefined
  const fn = spec.functions.find(fn => fn.name === "toggle")!
  const variants = fn.variants!.variant
  const sizes = fn.variants!.size
  const styles = Object.entries(variants).flatMap(([variant, classes]) => Object.entries(sizes).map(([size, sizeClasses]) =>
    `    {${JSON.stringify(variant)}, ${JSON.stringify(size)}} => ${JSON.stringify(cn(fn.baseClasses, classes, sizeClasses))}`)).join(",\n")
  return `defmodule ShadcnLiveview.Components.Toggle do
  @moduledoc """
  A native pressed button with explicit state and optional controlled LiveView events.
  Supply a stable id. With on_change, assign the event's boolean value back to pressed;
  without on_change, the colocated hook owns local pressed state until server state changes.
  Disabled controls remain inert. Arbitrary native button attrs pass through rest.
  """
  use Phoenix.Component
  import ShadcnLiveview.Helpers, only: [classes: 1]

  @styles %{
${styles}
  }

  attr :id, :string, required: true
  attr :pressed, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :variant, :string, default: "default", values: ${JSON.stringify(Object.keys(variants))}
  attr :size, :string, default: "default", values: ${JSON.stringify(Object.keys(sizes))}
  attr :on_change, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(form name value)
  slot :inner_block, required: true

  @doc "Renders the pressed state; on_change receives id and boolean value."
  def toggle(assigns) do
    assigns = assign(assigns, :styles, Map.fetch!(@styles, {assigns.variant, assigns.size}))
    ~H"""
    <button id={@id} type="button" data-slot="toggle" aria-pressed={to_string(@pressed)}
      data-state={if @pressed, do: "on", else: "off"} data-disabled={if @disabled, do: ""}
      disabled={@disabled} class={classes([@styles, @class])} phx-hook=".Toggle"
      phx-pressed={to_string(@pressed)} phx-change-event={@on_change} {@rest}>
      {render_slot(@inner_block)}
    </button>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Toggle">
      export default {
        mounted() {
          this.serverPressed = this.el.getAttribute("phx-pressed");
          this.click = () => {
            if (this.el.disabled) return;
            const value = this.el.getAttribute("aria-pressed") !== "true";
            const event = this.el.getAttribute("phx-change-event");
            if (event) this.pushEvent(event, {id: this.el.id, value});
            else this.setPressed(value);
          };
          this.el.addEventListener("click", this.click);
        },
        setPressed(value) {
          this.el.setAttribute("aria-pressed", String(value));
          this.el.setAttribute("data-state", value ? "on" : "off");
        },
        beforeUpdate() { this.localPressed = this.el.getAttribute("aria-pressed") === "true"; },
        updated() {
          const value = this.el.getAttribute("phx-pressed");
          if (value !== this.serverPressed || this.el.getAttribute("phx-change-event")) {
            this.serverPressed = value;
            this.setPressed(value === "true");
          }
          else this.setPressed(this.localPressed);
        },
        destroyed() { this.el.removeEventListener("click", this.click); }
      }
    </script>
    """
  end
end
`
}
