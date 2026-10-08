defmodule ShadcnLiveview.Components.Toggle do
  @moduledoc """
  A native pressed button with explicit state and optional controlled LiveView events.
  Supply a stable id. With on_change, assign the event's boolean value back to pressed;
  without on_change, the colocated hook owns local pressed state until server state changes.
  Disabled controls remain inert. Arbitrary native button attrs pass through rest.
  """
  use Phoenix.Component
  import ShadcnLiveview.Helpers, only: [classes: 1]

  @styles %{
    {"default", "default"} =>
      "group/toggle inline-flex items-center justify-center gap-1 rounded-lg text-sm font-medium whitespace-nowrap transition-all outline-none hover:bg-muted hover:text-foreground focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50 disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-destructive/20 aria-pressed:bg-muted data-[state=on]:bg-muted dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 bg-transparent h-8 min-w-8 px-2.5 has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2",
    {"default", "sm"} =>
      "group/toggle inline-flex items-center justify-center gap-1 font-medium whitespace-nowrap transition-all outline-none hover:bg-muted hover:text-foreground focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50 disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-destructive/20 aria-pressed:bg-muted data-[state=on]:bg-muted dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 bg-transparent h-7 min-w-7 rounded-[min(var(--radius-md),12px)] px-2.5 text-[0.8rem] has-data-[icon=inline-end]:pr-1.5 has-data-[icon=inline-start]:pl-1.5 [&_svg:not([class*='size-'])]:size-3.5",
    {"default", "lg"} =>
      "group/toggle inline-flex items-center justify-center gap-1 rounded-lg text-sm font-medium whitespace-nowrap transition-all outline-none hover:bg-muted hover:text-foreground focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50 disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-destructive/20 aria-pressed:bg-muted data-[state=on]:bg-muted dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 bg-transparent h-9 min-w-9 px-2.5 has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2",
    {"outline", "default"} =>
      "group/toggle inline-flex items-center justify-center gap-1 rounded-lg text-sm font-medium whitespace-nowrap transition-all outline-none hover:text-foreground focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50 disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-destructive/20 aria-pressed:bg-muted data-[state=on]:bg-muted dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 border border-input bg-transparent hover:bg-muted h-8 min-w-8 px-2.5 has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2",
    {"outline", "sm"} =>
      "group/toggle inline-flex items-center justify-center gap-1 font-medium whitespace-nowrap transition-all outline-none hover:text-foreground focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50 disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-destructive/20 aria-pressed:bg-muted data-[state=on]:bg-muted dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 border border-input bg-transparent hover:bg-muted h-7 min-w-7 rounded-[min(var(--radius-md),12px)] px-2.5 text-[0.8rem] has-data-[icon=inline-end]:pr-1.5 has-data-[icon=inline-start]:pl-1.5 [&_svg:not([class*='size-'])]:size-3.5",
    {"outline", "lg"} =>
      "group/toggle inline-flex items-center justify-center gap-1 rounded-lg text-sm font-medium whitespace-nowrap transition-all outline-none hover:text-foreground focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50 disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-destructive/20 aria-pressed:bg-muted data-[state=on]:bg-muted dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 border border-input bg-transparent hover:bg-muted h-9 min-w-9 px-2.5 has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2"
  }

  attr :id, :string, required: true
  attr :pressed, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :variant, :string, default: "default", values: ["default", "outline"]
  attr :size, :string, default: "default", values: ["default", "sm", "lg"]
  attr :on_change, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(form name value)
  slot :inner_block, required: true

  @doc "Renders the pressed state; on_change receives id and boolean value."
  def toggle(assigns) do
    assigns = assign(assigns, :styles, Map.fetch!(@styles, {assigns.variant, assigns.size}))

    ~H"""
    <button
      id={@id}
      type="button"
      data-slot="toggle"
      aria-pressed={to_string(@pressed)}
      data-state={if @pressed, do: "on", else: "off"}
      data-disabled={if @disabled, do: ""}
      disabled={@disabled}
      class={classes([@styles, @class])}
      phx-hook=".Toggle"
      phx-pressed={to_string(@pressed)}
      phx-change-event={@on_change}
      {@rest}
    >
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
