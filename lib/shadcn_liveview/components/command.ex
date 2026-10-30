defmodule ShadcnLiveview.Components.Command do
  @moduledoc "A command palette with explicit root context, native search inputs, and a colocated filtering/keyboard hook. Pass the root :let context to input and list. Items require stable IDs and explicit values. Filtering ranks items with CSS order while retaining server-owned DOM placement; keyboard navigation follows the same visual order. As in cmdk SSR, item registration and initial selection/filtering happen when the client mounts. on_select optionally pushes an event with id and value to the nearest phx-target ancestor, or the owning LiveView when absent; the search input retains native name/form semantics."
  use Phoenix.Component
  import ShadcnLiveview.Helpers
  alias ShadcnLiveview.Components.Icon

  @doc "Renders a command root; :let receives its stable IDs and selected value."
  attr :id, :string,
    required: true,
    doc:
      "Stable, unique DOM id, constant across renders; the colocated hook and event payloads use it."

  attr :value, :string, default: ""
  attr :label, :string, default: ""
  attr :loop, :boolean, default: false
  attr :should_filter, :boolean, default: true

  attr :on_select, :string,
    default: nil,
    doc:
      "LiveView event name pushed on select; the payload is described in the module docs. `nil` pushes no event."

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global
  slot :inner_block, required: true

  def command(assigns) do
    assigns =
      assign(assigns, :context, %{
        id: assigns.id,
        value: assigns.value,
        input_id: "radix-#{assigns.id}-input",
        label_id: "radix-#{assigns.id}-label",
        list_id: "radix-#{assigns.id}-list"
      })

    ~H"""
    <div
      id={@id}
      tabindex="-1"
      data-slot="command"
      cmdk-root=""
      class={
        classes([
          "flex size-full flex-col overflow-hidden rounded-xl! bg-popover p-1 text-popover-foreground",
          @class
        ])
      }
      phx-hook=".Command"
      phx-value-selected={@value}
      phx-value-loop={to_string(@loop)}
      phx-value-filter={to_string(@should_filter)}
      phx-value-event={@on_select}
      {@rest}
    >
      <label
        cmdk-label=""
        for={@context.input_id}
        id={@context.label_id}
        style="position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip:rect(0, 0, 0, 0);white-space:nowrap;border-width:0"
      >{@label}</label>
      {render_slot(@inner_block, @context)}
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Command">
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
      this.listeners = [];
      this.itemOrder = [];
      this.listen = (node, type, handler) => { node.addEventListener(type, handler); this.listeners.push([node, type, handler]); };
      this.listen(this.el, "input", e => { if (e.target.matches("[cmdk-input]")) this.filter(); });
      this.listen(this.el, "keydown", e => {
        if (!e.target.matches("[cmdk-input]") || e.target.disabled || e.isComposing) return;
        const items = this.available();
        const current = items.findIndex(item => item.getAttribute("data-selected") === "true");
        let next;
        if (e.key === "ArrowDown") next = current + 1;
        if (e.key === "ArrowUp") next = current < 0 ? items.length - 1 : current - 1;
        if (e.key === "Home") next = 0;
        if (e.key === "End") next = items.length - 1;
        if (next !== undefined && items.length) {
          e.preventDefault();
          if (this.el.getAttribute("phx-value-loop") === "true") next = (next + items.length) % items.length;
          this.select(items[Math.max(0, Math.min(next, items.length - 1))]);
        }
        if (e.key === "Enter") {
          const item = items.find(item => item.getAttribute("data-selected") === "true");
          if (item) { e.preventDefault(); this.activate(item); }
        }
      });
      this.listen(this.el, "click", e => {
        const item = e.target.closest("[cmdk-item]");
        if (item && this.el.contains(item) && item.getAttribute("data-disabled") !== "true" && !item.hidden) this.activate(item);
      });
      this.listen(this.el, "pointermove", e => {
        const item = e.target.closest("[cmdk-item]");
        if (item && this.el.contains(item) && item.getAttribute("data-disabled") !== "true" && !item.hidden) this.select(item);
      });
      this.filter();
      },
      available() { return this.itemOrder.filter(item => !item.hidden && item.getAttribute("data-disabled") !== "true"); },
      select(item) {
      this.el.querySelectorAll("[cmdk-item]").forEach(node => {
        const selected = node === item;
        node.setAttribute("data-selected", String(selected)); node.setAttribute("aria-selected", String(selected));
      });
      const input = this.el.querySelector("[cmdk-input]");
      if (input) { if (item) input.setAttribute("aria-activedescendant", item.id); else input.removeAttribute("aria-activedescendant"); }
      if (this.el.contains(document.activeElement)) item?.scrollIntoView({block: "nearest"});
      },
      score(text, query) {
      // cmdk command-score: contiguous and word-boundary matches outrank gaps;
      // casing, skipped boundaries and transpositions receive the same penalties.
      const lower = text.toLowerCase().replace(/[\s-]/g, " ");
      const search = query.toLowerCase().replace(/[\s-]/g, " ");
      const memo = new Map();
      const recurse = (start, index) => {
        if (index === query.length) return start === text.length ? 1 : 0.99;
        const key = start + "," + index;
        if (memo.has(key)) return memo.get(key);
        let best = 0;
        for (let position = lower.indexOf(search[index], start); position >= 0; position = lower.indexOf(search[index], position + 1)) {
          let score = recurse(position + 1, index + 1);
          if (score > best) {
            if (position === start) score *= 1;
            else if (/[\\\/_+.#"@\[\(\{&]/.test(text[position - 1])) {
              score *= 0.8;
              const boundaries = text.slice(start, position - 1).match(/[\\\/_+.#"@\[\(\{&]/g);
              if (boundaries && start > 0) score *= Math.pow(0.999, boundaries.length);
            } else if (/[\s-]/.test(text[position - 1])) {
              score *= 0.9;
              const boundaries = text.slice(start, position - 1).match(/[\s-]/g);
              if (boundaries && start > 0) score *= Math.pow(0.999, boundaries.length);
            } else {
              score *= 0.17;
              if (start > 0) score *= Math.pow(0.999, position - start);
            }
            if (text[position] !== query[index]) score *= 0.9999;
          }
          if ((score < 0.1 && lower[position - 1] === search[index + 1]) || (search[index + 1] === search[index] && lower[position - 1] !== search[index])) {
            score = Math.max(score, recurse(position + 1, index + 2) * 0.1);
          }
          best = Math.max(best, score);
        }
        memo.set(key, best); return best;
      };
      return recurse(0, 0);
      },
      filter() {
      const query = (this.el.querySelector("[cmdk-input]")?.value || "").trim();
      const shouldFilter = this.el.getAttribute("phx-value-filter") !== "false";
      let count = 0;
      const scores = new Map(), parents = new Set();
      this.el.querySelectorAll("[cmdk-item]").forEach(item => {
        const keywords = JSON.parse(item.getAttribute("phx-value-keywords") || "[]");
        const text = [item.getAttribute("phx-value-value"), ...keywords].join(" ");
        const score = !shouldFilter || !query ? 1 : this.score(text, query);
        scores.set(item, score); item.hidden = score === 0; if (score > 0) count++;
        parents.add(item.parentElement);
      });
      this.el.querySelectorAll("[cmdk-group]").forEach(group => {
        const items = Array.from(group.querySelectorAll("[cmdk-item]"));
        group.hidden = !items.some(item => !item.hidden);
        scores.set(group, Math.max(0, ...items.map(item => scores.get(item) || 0)));
        parents.add(group.parentElement);
      });
      const orders = new Map();
      parents.forEach(parent => {
        const children = Array.from(parent.children);
        const ranked = children.filter(node => scores.has(node));
        if (shouldFilter && query) ranked.sort((a, b) => scores.get(b) - scores.get(a));
        const ordered = shouldFilter && query ? [...children.filter(node => !scores.has(node)), ...ranked] : children;
        parent.style.display = "flex"; parent.style.flexDirection = "column";
        ordered.forEach((node, index) => { node.style.order = String(index); });
        orders.set(parent, ordered);
      });
      this.itemOrder = [];
      const visit = node => {
        if (node.matches("[cmdk-item]")) this.itemOrder.push(node);
        else (orders.get(node) || Array.from(node.children)).forEach(visit);
      };
      visit(this.el);
      this.el.querySelectorAll("[cmdk-empty]").forEach(empty => { empty.hidden = count !== 0; });
      this.el.querySelectorAll("[cmdk-separator]").forEach(separator => { separator.hidden = query !== ""; });
      const items = this.available();
      const selected = this.el.getAttribute("phx-value-selected");
      this.select(items.find(item => item.getAttribute("phx-value-value") === selected) || items[0]);
      },
      activate(item) {
      this.select(item);
      const value = item.getAttribute("phx-value-value") || item.textContent.trim();
      const previous = this.el.getAttribute("phx-value-selected");
      this.el.setAttribute("phx-value-selected", value);
      this.el.dispatchEvent(new CustomEvent("shadcn:command-change", {bubbles: true, detail: {id: this.el.id, value}}));
      const event = this.el.getAttribute("phx-value-event");
      // The server owns the selected value, so a failed push restores it.
      if (event) this.sendEvent(event, {id: this.el.id, value}).catch(() => {
        if (this.el.getAttribute("phx-value-selected") === value) { this.el.setAttribute("phx-value-selected", previous); this.filter(); }
      });
      },
      updated() { this.filter(); },
      destroyed() { this.listeners.forEach(([node, type, handler]) => node.removeEventListener(type, handler)); }
      }
    </script>
    """
  end

  attr :context, :map, required: true
  attr :value, :string, default: ""

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global,
    include:
      ~w(name form placeholder disabled required readonly autocomplete autocorrect spellcheck type)

  def command_input(assigns) do
    ~H"""
    <div data-slot="command-input-wrapper" class="p-1 pb-0">
      <div
        data-slot="input-group"
        role="group"
        class="group/input-group relative flex h-8 w-full min-w-0 items-center rounded-lg border transition-colors outline-none in-data-[slot=combobox-content]:focus-within:border-inherit in-data-[slot=combobox-content]:focus-within:ring-0 has-disabled:bg-input/50 has-disabled:opacity-50 has-[[data-slot=input-group-control]:focus-visible]:border-ring has-[[data-slot=input-group-control]:focus-visible]:ring-3 has-[[data-slot=input-group-control]:focus-visible]:ring-ring/50 has-[[data-slot][aria-invalid=true]]:border-destructive has-[[data-slot][aria-invalid=true]]:ring-3 has-[[data-slot][aria-invalid=true]]:ring-destructive/20 has-[>[data-align=block-end]]:h-auto has-[>[data-align=block-end]]:flex-col has-[>[data-align=block-start]]:h-auto has-[>[data-align=block-start]]:flex-col has-[>textarea]:h-auto dark:bg-input/30 dark:has-disabled:bg-input/80 dark:has-[[data-slot][aria-invalid=true]]:ring-destructive/40 has-[>[data-align=block-end]]:[&>input]:pt-3 has-[>[data-align=block-start]]:[&>input]:pb-3 has-[>[data-align=inline-end]]:[&>input]:pr-1.5 has-[>[data-align=inline-start]]:[&>input]:pl-1.5 h-8! rounded-lg! border-input/30 bg-input/30 shadow-none! *:data-[slot=input-group-addon]:pl-2!"
      >
        <input
          data-slot="command-input"
          class={
            classes([
              "w-full text-sm outline-hidden disabled:cursor-not-allowed disabled:opacity-50",
              @class
            ])
          }
          cmdk-input=""
          autocomplete="off"
          autocorrect="off"
          spellcheck="false"
          aria-autocomplete="list"
          role="combobox"
          aria-expanded="true"
          aria-controls={@context.list_id}
          aria-labelledby={@context.label_id}
          id={@context.input_id}
          type="text"
          value={@value}
          {@rest}
        />
        <div
          role="group"
          data-slot="input-group-addon"
          data-align="inline-start"
          class="flex h-auto cursor-text items-center justify-center gap-2 py-1.5 text-sm font-medium text-muted-foreground select-none group-data-[disabled=true]/input-group:opacity-50 [&>kbd]:rounded-[calc(var(--radius)-5px)] [&>svg:not([class*='size-'])]:size-4 order-first pl-2 has-[>button]:ml-[-0.3rem] has-[>kbd]:ml-[-0.15rem]"
        >
          <Icon.icon name="search" class="size-4 shrink-0 opacity-50" />
        </div>
      </div>
    </div>
    """
  end

  attr :context, :map, required: true
  attr :label, :string, default: "Suggestions"

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global
  slot :inner_block, required: true

  def command_list(assigns) do
    ~H"""
    <div
      data-slot="command-list"
      class={
        classes([
          "no-scrollbar max-h-72 scroll-py-1 overflow-x-hidden overflow-y-auto outline-none",
          @class
        ])
      }
      cmdk-list=""
      role="listbox"
      tabindex="-1"
      aria-label={@label}
      id={@context.list_id}
      {@rest}
    >
      <div cmdk-list-sizer="">{render_slot(@inner_block)}</div>
    </div>
    """
  end

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global
  slot :inner_block, required: true

  def command_empty(assigns) do
    ~H"""
    <div
      data-slot="command-empty"
      class={classes(["py-6 text-center text-sm", @class])}
      cmdk-empty=""
      role="presentation"
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :id, :string,
    required: true,
    doc:
      "Stable, unique DOM id, constant across renders; the colocated hook and event payloads use it."

  attr :heading, :string, default: nil

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global
  slot :inner_block, required: true

  def command_group(assigns) do
    ~H"""
    <div
      data-slot="command-group"
      class={
        classes([
          "overflow-hidden p-1 text-foreground **:[[cmdk-group-heading]]:px-2 **:[[cmdk-group-heading]]:py-1.5 **:[[cmdk-group-heading]]:text-xs **:[[cmdk-group-heading]]:font-medium **:[[cmdk-group-heading]]:text-muted-foreground",
          @class
        ])
      }
      cmdk-group=""
      role="presentation"
      {@rest}
    >
      <div :if={@heading} cmdk-group-heading="" aria-hidden="true" id={"radix-#{@id}-heading"}>
        {@heading}
      </div>
      <div cmdk-group-items="" role="group" aria-labelledby={@heading && "radix-#{@id}-heading"}>
        {render_slot(@inner_block)}
      </div>
    </div>
    """
  end

  @doc "Items are registered by the client hook; disabled items cannot be selected."
  attr :id, :string,
    required: true,
    doc:
      "Stable, unique DOM id, constant across renders; the colocated hook and event payloads use it."

  attr :value, :string, required: true
  attr :keywords, :list, default: []
  attr :disabled, :boolean, default: false

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global
  slot :inner_block, required: true

  def command_item(assigns) do
    ~H"""
    <div
      data-slot="command-item"
      class={
        classes([
          "group/command-item relative flex cursor-default items-center gap-2 rounded-sm px-2 py-1.5 text-sm outline-hidden select-none in-data-[slot=dialog-content]:rounded-lg! data-[disabled=true]:pointer-events-none data-[disabled=true]:opacity-50 data-selected:bg-muted data-selected:text-foreground [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 data-selected:*:[svg]:text-foreground",
          @class
        ])
      }
      id={@id}
      cmdk-item=""
      role="option"
      aria-disabled={to_string(@disabled)}
      aria-selected="false"
      data-disabled={to_string(@disabled)}
      data-selected="false"
      phx-value-value={@value}
      phx-value-keywords={Jason.encode!(@keywords)}
      {@rest}
    >
      {render_slot(@inner_block)}
      <Icon.icon
        name="check"
        class="ml-auto opacity-0 group-has-data-[slot=command-shortcut]/command-item:hidden group-data-[checked=true]/command-item:opacity-100"
      />
    </div>
    """
  end

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global

  def command_separator(assigns) do
    ~H"""
    <div
      data-slot="command-separator"
      class={classes(["-mx-1 h-px bg-border", @class])}
      cmdk-separator=""
      role="separator"
      {@rest}
    />
    """
  end

  attr :class, :any,
    default: nil,
    doc:
      "Extra classes appended to the defaults: a string or a HEEx-style list whose `nil` and `false` entries are dropped."

  attr :rest, :global
  slot :inner_block, required: true

  def command_shortcut(assigns) do
    ~H"""
    <span
      data-slot="command-shortcut"
      class={
        classes([
          "ml-auto text-xs tracking-widest text-muted-foreground group-data-selected/command-item:text-foreground",
          @class
        ])
      }
      {@rest}
    >{render_slot(@inner_block)}</span>
    """
  end
end
