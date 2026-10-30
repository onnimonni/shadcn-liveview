defmodule ShadcnLiveview.Components.Avatar do
  @moduledoc ~S"""
  An image element with a fallback for representing a user.

  As with Radix, `avatar_fallback` shows until `avatar_image` has loaded (and again after a load
  error or a new `src`), and the image is shown only once loaded. A bundled script mirrors the
  load into the image's `data-status` (`loading`/`loaded`/`error`) and the library CSS applies it,
  so render both; no id or hook is needed.

  Upstream: https://ui.shadcn.com/docs/components/radix/avatar

  Components: `avatar/1`, `avatar_image/1`, `avatar_fallback/1`, `avatar_badge/1`, `avatar_group/1`, `avatar_group_count/1`.

  Example (locally authored, rendered by the SSR parity fixtures):

  ```heex
  <.avatar>
    <.avatar_fallback>CN</.avatar_fallback>
  </.avatar>
  ```
  """
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :size, :string, default: "default", values: ~w(default sm lg)

  attr :rest, :global,
    include:
      ~w(accept alt autocomplete autofocus checked cols disabled download for form formaction formenctype formmethod formnovalidate formtarget height href list max maxlength min minlength multiple name pattern placeholder readonly rel required rows selected src step target type value width)

  slot :inner_block, required: false

  def avatar(assigns) do
    ~H"""
    <span
      data-slot="avatar"
      data-size={@size}
      class={
        classes([
          "group/avatar relative flex size-8 shrink-0 rounded-full select-none after:absolute after:inset-0 after:rounded-full after:border after:border-border after:mix-blend-darken data-[size=lg]:size-10 data-[size=sm]:size-6 dark:after:mix-blend-lighten",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
      <script :type={Phoenix.LiveView.ColocatedJS}>
        const key = Symbol.for("shadcn-liveview.avatar-status");
        if (!window[key]) {
          window[key] = true;
          const selector = 'img[data-slot="avatar-image"]';
          const known = new WeakMap();
          const mark = (img, status) => {
            known.set(img, {src: img.src, status});
            if (img.getAttribute("data-status") !== status) img.setAttribute("data-status", status);
          };
          const sync = img => {
            const state = known.get(img);
            if (state && state.src === img.src) {
              if (img.getAttribute("data-status") !== state.status) img.setAttribute("data-status", state.status);
            } else if (!img.getAttribute("src")) mark(img, "error");
            else if (img.complete) mark(img, img.naturalWidth > 0 ? "loaded" : "error");
            else mark(img, "loading");
          };
          const scan = root => {
            if (root.matches?.(selector)) sync(root);
            root.querySelectorAll?.(selector).forEach(sync);
          };
          for (const [type, status] of [["load", "loaded"], ["error", "error"]]) {
            document.addEventListener(type, event => { if (event.target.matches?.(selector)) mark(event.target, status); }, true);
          }
          new MutationObserver(records => {
            for (const record of records) {
              if (record.type === "attributes") { if (record.target.matches(selector)) sync(record.target); }
              else record.addedNodes.forEach(node => { if (node.nodeType === 1) scan(node); });
            }
          }).observe(document.documentElement, {subtree: true, childList: true, attributes: true, attributeFilter: ["src", "data-status", "data-slot"]});
          scan(document);
        }
      </script>
    </span>
    """
  end

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global,
    include:
      ~w(accept alt autocomplete autofocus checked cols disabled download for form formaction formenctype formmethod formnovalidate formtarget height href list max maxlength min minlength multiple name pattern placeholder readonly rel required rows selected src step target type value width)

  def avatar_image(assigns) do
    ~H"""
    <img
      data-slot="avatar-image"
      class={classes(["aspect-square size-full rounded-full object-cover", @class])}
      {@rest}
    />
    """
  end

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global,
    include:
      ~w(accept alt autocomplete autofocus checked cols disabled download for form formaction formenctype formmethod formnovalidate formtarget height href list max maxlength min minlength multiple name pattern placeholder readonly rel required rows selected src step target type value width)

  slot :inner_block, required: false

  def avatar_fallback(assigns) do
    ~H"""
    <span
      data-slot="avatar-fallback"
      class={
        classes([
          "flex size-full items-center justify-center rounded-full bg-muted text-sm text-muted-foreground group-data-[size=sm]/avatar:text-xs",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global,
    include:
      ~w(accept alt autocomplete autofocus checked cols disabled download for form formaction formenctype formmethod formnovalidate formtarget height href list max maxlength min minlength multiple name pattern placeholder readonly rel required rows selected src step target type value width)

  slot :inner_block, required: false

  def avatar_badge(assigns) do
    ~H"""
    <span
      data-slot="avatar-badge"
      class={
        classes([
          "absolute right-0 bottom-0 z-10 inline-flex items-center justify-center rounded-full bg-primary text-primary-foreground bg-blend-color ring-2 ring-background select-none group-data-[size=sm]/avatar:size-2 group-data-[size=sm]/avatar:[&>svg]:hidden group-data-[size=default]/avatar:size-2.5 group-data-[size=default]/avatar:[&>svg]:size-2 group-data-[size=lg]/avatar:size-3 group-data-[size=lg]/avatar:[&>svg]:size-2",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </span>
    """
  end

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global,
    include:
      ~w(accept alt autocomplete autofocus checked cols disabled download for form formaction formenctype formmethod formnovalidate formtarget height href list max maxlength min minlength multiple name pattern placeholder readonly rel required rows selected src step target type value width)

  slot :inner_block, required: false

  def avatar_group(assigns) do
    ~H"""
    <div
      data-slot="avatar-group"
      class={
        classes([
          "group/avatar-group flex -space-x-2 *:data-[slot=avatar]:ring-2 *:data-[slot=avatar]:ring-background",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global,
    include:
      ~w(accept alt autocomplete autofocus checked cols disabled download for form formaction formenctype formmethod formnovalidate formtarget height href list max maxlength min minlength multiple name pattern placeholder readonly rel required rows selected src step target type value width)

  slot :inner_block, required: false

  def avatar_group_count(assigns) do
    ~H"""
    <div
      data-slot="avatar-group-count"
      class={
        classes([
          "relative flex size-8 shrink-0 items-center justify-center rounded-full bg-muted text-sm text-muted-foreground ring-2 ring-background group-has-data-[size=lg]/avatar-group:size-10 group-has-data-[size=sm]/avatar-group:size-6 [&>svg]:size-4 group-has-data-[size=lg]/avatar-group:[&>svg]:size-5 group-has-data-[size=sm]/avatar-group:[&>svg]:size-3",
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end
end
