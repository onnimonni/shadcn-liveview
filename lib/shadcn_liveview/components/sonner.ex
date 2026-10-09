defmodule ShadcnLiveview.Components.Sonner do
  @moduledoc false
  use Phoenix.Component

  @doc "Mount with a stable id. push_event(socket, \"shadcn:toast\", %{toaster: id, message: text, description: text, duration: milliseconds}) displays escaped notifications. Zero duration persists until dismissed; omitted duration is 4000ms."
  attr :id, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global

  def toaster(assigns) do
    ~H"""
    <section
      :if={is_nil(@id)}
      aria-label="Notifications alt+T"
      tabindex="-1"
      aria-live="polite"
      aria-relevant="additions text"
      aria-atomic="false"
      data-react-aria-top-layer="true"
      {@rest}
    />
    <section
      :if={@id}
      id={@id}
      phx-hook=".Notifications"
      phx-update="ignore"
      aria-label="Notifications alt+T"
      tabindex="-1"
      aria-live="polite"
      aria-relevant="additions text"
      aria-atomic="false"
      data-react-aria-top-layer="true"
      class={@class}
      {@rest}
    />
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Notifications">
      export default {
        mounted() {
          this.timers = new Map();
          this.list = document.createElement("ol");
          this.list.dataset.sonnerToaster = "true";
          this.list.className = "fixed right-6 bottom-6 z-50 flex w-[356px] max-w-[calc(100vw-48px)] flex-col gap-2";
          this.el.append(this.list);
          this.handleEvent("shadcn:toast", toast => {
            if (toast.toaster && toast.toaster !== this.el.id) return;
            const item = document.createElement("li");
            item.dataset.sonnerToast = "true";
            item.className = "relative rounded-lg border bg-popover p-4 text-sm text-popover-foreground shadow-lg";
            const title = document.createElement("div");
            title.className = "pr-6 font-medium"; title.textContent = toast.message;
            item.append(title);
            if (toast.description) {
              const description = document.createElement("div");
              description.className = "mt-1 text-muted-foreground";
              description.textContent = toast.description; item.append(description);
            }
            const close = document.createElement("button");
            close.type = "button"; close.setAttribute("aria-label", "Dismiss notification");
            close.className = "absolute top-2 right-2 rounded p-1 focus-visible:ring-2";
            close.textContent = "×";
            close.addEventListener("click", () => this.dismiss(item));
            item.append(close); this.list.append(item);
            const duration = toast.duration ?? 4000;
            if (duration > 0) this.timers.set(item, setTimeout(() => this.dismiss(item), duration));
          });
          this.key = event => {
            if (event.altKey && event.code === "KeyT" && this.list.lastElementChild) {
              event.preventDefault(); this.list.lastElementChild.querySelector("button").focus();
            }
          };
          document.addEventListener("keydown", this.key);
        },
        dismiss(item) { clearTimeout(this.timers.get(item)); this.timers.delete(item); item.remove(); },
        destroyed() {
          for (const timer of this.timers.values()) clearTimeout(timer);
          document.removeEventListener("keydown", this.key);
        }
      }
    </script>
    """
  end
end
