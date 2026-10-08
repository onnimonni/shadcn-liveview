defmodule ShadcnLiveview.Components.Tabs do
  @moduledoc false
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :dir, :string, default: "ltr"
  attr :orientation, :string, default: "horizontal"
  attr :default_value, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def tabs(assigns) do
    ~H"""
    <div
      dir={@dir}
      data-orientation={@orientation}
      data-slot="tabs"
      phx-hook=".Tabs"
      class={classes(["group/tabs flex gap-2 data-horizontal:flex-col", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Tabs">
      export default {
        mounted() {
          this.el.addEventListener("click", (e) => {
            const trigger = e.target.closest("[data-slot=tabs-trigger]");
            if (!trigger) return;
            const val = trigger.getAttribute("data-value") || trigger.getAttribute("value");
            this.el.querySelectorAll("[data-slot=tabs-trigger]").forEach((t) => {
              const match = (t.getAttribute("data-value") || t.getAttribute("value")) === val;
              t.setAttribute("data-state", match ? "active" : "inactive");
              t.setAttribute("aria-selected", match ? "true" : "false");
            });
            this.el.querySelectorAll("[data-slot=tabs-content]").forEach((c) => {
              const match = (c.getAttribute("data-value") || c.getAttribute("value")) === val;
              c.setAttribute("data-state", match ? "active" : "inactive");
              c.hidden = !match;
            });
          });
        }
      }
    </script>
    """
  end

  attr :variant, :string, default: "default"
  attr :orientation, :string, default: "horizontal"
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def tabs_list(assigns) do
    ~H"""
    <div
      role="tablist"
      aria-orientation={@orientation}
      tabindex="-1"
      data-orientation={@orientation}
      data-slot="tabs-list"
      data-variant={@variant}
      style="outline:none"
      class={classes(["group/tabs-list inline-flex w-fit items-center justify-center rounded-lg p-[3px] text-muted-foreground group-data-horizontal/tabs:h-8 group-data-vertical/tabs:h-fit group-data-vertical/tabs:flex-col data-[variant=line]:rounded-none bg-muted", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :value, :string, required: true
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def tabs_trigger(assigns) do
    active = (assigns.value == "account")
    assigns = assign(assigns, :active, active)
    ~H"""
    <button
      type="button"
      role="tab"
      aria-selected={to_string(@active)}
      aria-controls="radix-id"
      data-state={if @active, do: "active", else: "inactive"}
      id="radix-id"
      tabindex="-1"
      data-orientation="horizontal"
      data-slot="tabs-trigger"
      class={classes(["relative inline-flex h-[calc(100%-1px)] flex-1 items-center justify-center gap-1.5 rounded-md border border-transparent px-1.5 py-0.5 text-sm font-medium whitespace-nowrap text-foreground/60 transition-all group-data-vertical/tabs:w-full group-data-vertical/tabs:justify-start hover:text-foreground focus-visible:border-ring focus-visible:ring-[3px] focus-visible:ring-ring/50 focus-visible:outline-1 focus-visible:outline-ring disabled:pointer-events-none disabled:opacity-50 has-data-[icon=inline-end]:pr-1 has-data-[icon=inline-start]:pl-1 dark:text-muted-foreground dark:hover:text-foreground group-data-[variant=default]/tabs-list:data-active:shadow-sm group-data-[variant=line]/tabs-list:data-active:shadow-none [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 group-data-[variant=line]/tabs-list:bg-transparent group-data-[variant=line]/tabs-list:data-active:bg-transparent dark:group-data-[variant=line]/tabs-list:data-active:border-transparent dark:group-data-[variant=line]/tabs-list:data-active:bg-transparent data-active:bg-background data-active:text-foreground dark:data-active:border-input dark:data-active:bg-input/30 dark:data-active:text-foreground after:absolute after:bg-foreground after:opacity-0 after:transition-opacity group-data-horizontal/tabs:after:inset-x-0 group-data-horizontal/tabs:after:bottom-[-5px] group-data-horizontal/tabs:after:h-0.5 group-data-vertical/tabs:after:inset-y-0 group-data-vertical/tabs:after:-right-1 group-data-vertical/tabs:after:w-0.5 group-data-[variant=line]/tabs-list:data-active:after:opacity-100", @class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  attr :value, :string, required: true
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(href src alt type id name disabled placeholder value default_value default_size direction open ratio max min step dir align heading is_active config index max_length for)
  slot :inner_block, required: false

  def tabs_content(assigns) do
    active = (assigns.value == "account")
    assigns = assign(assigns, :active, active)
    ~H"""
    <div
      data-state={if @active, do: "active", else: "inactive"}
      data-orientation="horizontal"
      role="tabpanel"
      aria-labelledby="radix-id"
      id="radix-id"
      tabindex="0"
      data-slot="tabs-content"
      class={classes(["flex-1 text-sm outline-none", @class])}
      hidden={not @active}
      {if @active, do: %{style: "animation-duration:0s"}, else: %{}}
      {@rest}
    ><%= if @active do %>{render_slot(@inner_block)}<% end %></div>
    """
  end
end
