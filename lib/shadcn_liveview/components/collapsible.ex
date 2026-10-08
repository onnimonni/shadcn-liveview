defmodule ShadcnLiveview.Components.Collapsible do
  @moduledoc """
  Server-controlled disclosure. Pass the root's :let context to its trigger and
  content. on_open_change receives %{"id" => id, "open" => boolean}; assign
  the returned open value on the next render. Closed content has no child markup.
  """
  use Phoenix.Component
  import ShadcnLiveview.Helpers, only: [classes: 1]

  attr :id, :string, required: true
  attr :open, :boolean, default: false
  attr :disabled, :boolean, default: false
  attr :on_open_change, :string, default: "control_open"
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def collapsible(assigns) do
    context = %{id: assigns.id, open: assigns.open, disabled: assigns.disabled}
    assigns = assign(assigns, :context, context)

    ~H"""
    <div
      id={@id}
      data-state={if @open, do: "open", else: "closed"}
      data-disabled={if @disabled, do: ""}
      data-slot="collapsible"
      class={classes([@class])}
      phx-hook=".Collapsible"
      phx-value-change={@on_open_change}
      {@rest}
    >
      {render_slot(@inner_block, @context)}
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Collapsible">
      export default {
        mounted() {
          this.click = event => {
            const trigger = event.target.closest('[data-slot="collapsible-trigger"]');
            if (!trigger || !this.el.contains(trigger) || trigger.disabled) return;
            this.pushEvent(this.el.getAttribute("phx-value-change"), {id:this.el.id, open:this.el.getAttribute("data-state") !== "open"});
          };
          this.el.addEventListener("click", this.click);
        },
        updated() {},
        destroyed() { this.el.removeEventListener("click", this.click); }
      }
    </script>
    """
  end

  attr :context, :map, required: true
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled)
  slot :inner_block, required: true

  def collapsible_trigger(assigns) do
    ~H"""
    <button
      type="button"
      aria-controls={if @context.open, do: "radix-" <> @context.id <> "-content"}
      aria-expanded={to_string(@context.open)}
      data-state={if @context.open, do: "open", else: "closed"}
      data-disabled={if @context.disabled, do: ""}
      disabled={@context.disabled}
      data-slot="collapsible-trigger"
      class={classes([@class])}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  attr :context, :map, required: true
  attr :force_mount, :boolean, default: false
  attr :class, :string, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def collapsible_content(assigns) do
    ~H"""
    <div
      id={"radix-" <> @context.id <> "-content"}
      data-state={if @context.open, do: "open", else: "closed"}
      data-disabled={if @context.disabled, do: ""}
      hidden={!@context.open && !@force_mount}
      data-slot="collapsible-content"
      class={classes([@class])}
      {@rest}
    >
      <%= if @context.open || @force_mount do %>
        {render_slot(@inner_block)}
      <% end %>
    </div>
    """
  end
end
