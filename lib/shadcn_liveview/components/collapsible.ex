defmodule ShadcnLiveview.Components.Collapsible do
  @moduledoc """
  Server-controlled disclosure. Pass the root's :let context to its trigger and
  content. on_open_change receives %{"id" => id, "open" => boolean}; assign
  the returned open value on the next render. Events respect the nearest
  phx-target, and nested triggers operate only their nearest collapsible root.
  Closed content has no child markup.
  """
  use Phoenix.Component
  import ShadcnLiveview.Helpers, only: [classes: 1]

  attr :id, :string,
    required: true,
    doc:
      "Stable, unique DOM id, constant across renders; the colocated hook and event payloads use it."

  attr :open, :boolean, default: false
  attr :disabled, :boolean, default: false

  attr :on_open_change, :string,
    default: "control_open",
    doc: "LiveView event name pushed on open change; the payload is described in the module docs."

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

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
          this.click = event => {
            const trigger = event.target.closest('[data-slot="collapsible-trigger"]');
            if (!trigger || trigger.closest('[data-slot="collapsible"]') !== this.el || trigger.disabled) return;
            this.sendEvent(this.el.getAttribute("phx-value-change"), {id:this.el.id, open:this.el.getAttribute("data-state") !== "open"});
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

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

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

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

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
