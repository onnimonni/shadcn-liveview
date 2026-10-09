export const selectionHook = String.raw`
      export default {
        sendEvent(event, payload, onReply) {
          const target = this.el.closest('[phx-target]')?.getAttribute("phx-target");
          if (target) return this.pushEventTo(target, event, payload, onReply);
          return this.pushEvent(event, payload, onReply);
        },
        mounted() {
          this.radio = this.el.dataset.slot === "radio-group";
          this.controlled = this.el.getAttribute("phx-controlled") === "true";
          this.values = JSON.parse(this.el.getAttribute("phx-values"));
          this.initial = [...this.values];
          this.click = e => {
            const item = e.target.closest(this.radio ? '[data-slot="radio-group-item"]' : '[data-slot="toggle-group-item"]');
            if (!item || !this.el.contains(item) || item.disabled) return;
            const value = this.value(item);
            let next;
            if (this.radio) next = [value];
            else if (this.el.getAttribute("phx-selection-type") === "single") next = this.values.includes(value) ? [] : [value];
            else next = this.values.includes(value) ? this.values.filter(v => v !== value) : [...this.values, value];
            this.change(next, item);
          };
          this.key = e => {
            const items = this.items().filter(i => !i.disabled);
            const index = items.indexOf(e.target);
            if (index < 0 || this.el.getAttribute("phx-roving") === "false") return;
            if (this.radio && e.key === "Enter") { e.preventDefault(); return; }
            const orientation = this.el.getAttribute("phx-orientation");
            let delta = 0;
            if (orientation !== "vertical" && e.key === "ArrowRight") delta = this.el.dir === "rtl" ? -1 : 1;
            if (orientation !== "vertical" && e.key === "ArrowLeft") delta = this.el.dir === "rtl" ? 1 : -1;
            if (orientation !== "horizontal" && e.key === "ArrowDown") delta = 1;
            if (orientation !== "horizontal" && e.key === "ArrowUp") delta = -1;
            let target;
            if (e.key === "Home") target = items[0];
            else if (e.key === "End") target = items.at(-1);
            else if (delta) {
              let n = index + delta;
              if (this.el.getAttribute("phx-loop") === "true") n = (n + items.length) % items.length;
              target = items[n];
            } else return;
            e.preventDefault();
            if (target) { this.tabstop(target); target.focus(); if (this.radio) this.change([this.value(target)], target); }
          };
          this.focus = e => { if (this.items().includes(e.target)) this.tabstop(e.target); };
          this.el.addEventListener("click", this.click);
          this.el.addEventListener("keydown", this.key);
          this.el.addEventListener("focusin", this.focus);
          this.form = this.radio ? (document.getElementById(this.el.getAttribute("phx-form")) || this.el.closest("form")) : null;
          this.reset = () => {
            if (this.controlled) this.change([...this.initial], null);
            else { this.values = [...this.initial]; this.paint(); }
          };
          this.form?.addEventListener("reset", this.reset);
          this.paint();
        },
        items() { return [...this.el.querySelectorAll(this.radio ? '[data-slot="radio-group-item"]' : '[data-slot="toggle-group-item"]')].filter(i => i.closest('[data-slot="radio-group"], [data-slot="toggle-group"]') === this.el); },
        value(item) { return this.radio ? item.value : item.getAttribute("phx-value"); },
        tabstop(item) { if (this.el.getAttribute("phx-roving") === "false") return; this.items().forEach(i => i.tabIndex = i === item && !i.disabled ? 0 : -1); },
        change(next, item) {
          if (JSON.stringify(next) === JSON.stringify(this.values)) return;
          if (!this.controlled) { this.values = next; this.paint(); }
          const value = this.radio || this.el.getAttribute("phx-selection-type") === "single" ? (next[0] || "") : next;
          const event = this.el.getAttribute("phx-change-event");
          if (event) this.sendEvent(event, {id: this.el.id, value});
          this.el.dispatchEvent(new CustomEvent("selection-change", {bubbles: true, detail: {value}}));
          if (this.radio && !this.controlled) {
            const input = item.nextElementSibling;
            input?.dispatchEvent(new Event("input", {bubbles: true}));
            input?.dispatchEvent(new Event("change", {bubbles: true}));
          }
        },
        paint() {
          const items = this.items();
          for (const item of items) {
            const checked = this.values.includes(this.value(item));
            item.dataset.state = this.radio ? (checked ? "checked" : "unchecked") : (checked ? "on" : "off");
            item.setAttribute(this.radio || this.el.getAttribute("phx-selection-type") === "single" ? "aria-checked" : "aria-pressed", String(checked));
            if (this.radio) {
              const input = item.nextElementSibling;
              if (input?.type === "radio") { input.checked = checked; const box = item.getBoundingClientRect(); input.style.width = box.width + "px"; input.style.height = box.height + "px"; }
              const indicator = item.querySelector('[data-slot="radio-group-indicator"]');
              if (!checked) indicator?.remove();
              else if (!indicator) {
                const indicator = document.createElement("span");
                indicator.dataset.slot = "radio-group-indicator";
                indicator.dataset.state = "checked";
                if (item.disabled) indicator.setAttribute("data-disabled", "");
                indicator.className = "flex size-4 items-center justify-center";
                const dot = document.createElement("span");
                dot.className = "absolute top-1/2 left-1/2 size-2 -translate-x-1/2 -translate-y-1/2 rounded-full bg-primary-foreground";
                indicator.appendChild(dot);
                item.appendChild(indicator);
              }
            }
          }
          if (this.el.getAttribute("phx-roving") !== "false") {
            this.el.tabIndex = items.some(i => !i.disabled) ? 0 : -1;
            this.tabstop(items.find(i => i === document.activeElement && !i.disabled) || items.find(i => this.values.includes(this.value(i)) && !i.disabled) || items.find(i => !i.disabled));
            if (items.some(i => i.tabIndex === 0)) this.el.tabIndex = -1;
          }
        },
        updated() { this.controlled = this.el.getAttribute("phx-controlled") === "true"; if (this.controlled) this.values = JSON.parse(this.el.getAttribute("phx-values")); this.paint(); },
        destroyed() { this.el.removeEventListener("click", this.click); this.el.removeEventListener("keydown", this.key); this.el.removeEventListener("focusin", this.focus); this.form?.removeEventListener("reset", this.reset); }
      }
`

export const menubarHook = String.raw`
      export default {
        sendEvent(event, payload, onReply) {
          const target = this.el.closest('[phx-target]')?.getAttribute("phx-target");
          if (target) return this.pushEventTo(target, event, payload, onReply);
          return this.pushEvent(event, payload, onReply);
        },
        mounted() {
          this.pendingFocus = null;
          this.click = e => {
            const trigger = e.target.closest('[data-slot="menubar-trigger"]');
            if (trigger && this.el.contains(trigger)) {
              if (!trigger.disabled) this.change(trigger.dataset.state === "open" ? "" : trigger.getAttribute("phx-menu-value"), false);
              return;
            }
            if (!this.owns(e.target)) return;
            const item = e.target.closest('[role^="menuitem"]');
            if (!item || item.hasAttribute("data-disabled")) return;
            if (item.dataset.slot === "menubar-sub-trigger") { this.submenu(item, true, false); return; }
            if (item.getAttribute("role") === "menuitemcheckbox") this.sendEvent(item.getAttribute("phx-change-event"), {id: item.id, value: item.getAttribute("aria-checked") !== "true"});
            if (item.getAttribute("role") === "menuitemradio") {
              const group = item.closest('[data-slot="menubar-radio-group"]');
              this.sendEvent(group.getAttribute("phx-change-event"), {id: group.id, value: item.getAttribute("phx-value")});
            }
            this.change("", false);
            this.activeTrigger?.focus();
          };
          this.pointer = e => {
            const trigger = e.target.closest('[data-slot="menubar-trigger"]');
            if (trigger && this.el.contains(trigger) && !trigger.disabled && this.value && this.value !== trigger.getAttribute("phx-menu-value")) this.change(trigger.getAttribute("phx-menu-value"), false);
            if (!this.owns(e.target)) return;
            const item = e.target.closest('[role^="menuitem"]');
            if (!item || item.hasAttribute("data-disabled")) return;
            item.focus();
            const menu = item.closest('[role="menu"]');
            for (const sibling of menu.querySelectorAll('[data-slot="menubar-sub-trigger"][aria-expanded="true"]')) {
              if (sibling !== item && sibling.closest('[role="menu"]') === menu) this.submenu(sibling, false, false);
            }
            if (item.dataset.slot === "menubar-sub-trigger" && item.getAttribute("aria-expanded") === "false") this.submenu(item, true, false);
          };
          this.outside = e => { if (!this.el.contains(e.target) && this.value) this.change("", false); };
          this.focus = e => {
            for (const trigger of this.triggers()) {
              if (trigger === e.target) { trigger.setAttribute("data-highlighted", ""); this.tabstop(trigger); }
              else trigger.removeAttribute("data-highlighted");
            }
          };
          this.key = e => this.keydown(e);
          this.layout = () => this.positionMenus();
          document.addEventListener("click", this.click);
          document.addEventListener("pointerover", this.pointer);
          document.addEventListener("pointerdown", this.outside);
          document.addEventListener("keydown", this.key);
          document.addEventListener("focusin", this.focus);
          window.addEventListener("resize", this.layout);
          document.addEventListener("scroll", this.layout, true);
          this.sync();
        },
        triggers() { return [...this.el.querySelectorAll('[data-slot="menubar-trigger"]')]; },
        owns(target) { return this.el.contains(target) && !!target.closest('[role="menu"]'); },
        tabstop(trigger) { this.triggers().forEach(t => t.tabIndex = t === trigger && !t.disabled ? 0 : -1); },
        change(value, keyboard) {
          if (keyboard && value === this.value) {
            const trigger = this.triggers().find(t => t.getAttribute("phx-menu-value") === value);
            const menu = document.getElementById(trigger?.getAttribute("phx-content-id"));
            if (menu && this.el.contains(menu)) this.menuItems(menu)[0]?.focus();
            return;
          }
          if (value !== this.value) {
            for (const sub of this.el.querySelectorAll('[data-slot="menubar-sub-trigger"][aria-expanded="true"]')) this.submenu(sub, false, false);
          }
          this.pendingFocus = keyboard ? this.triggers().find(t => t.getAttribute("phx-menu-value") === value)?.getAttribute("phx-content-id") : null;
          this.sendEvent(this.el.getAttribute("phx-change-event"), {id: this.el.id, value});
        },
        sync() {
          this.value = this.el.getAttribute("phx-value") || "";
          const triggers = this.triggers();
          this.activeTrigger = triggers.find(t => t.getAttribute("phx-menu-value") === this.value) || this.activeTrigger;
          this.tabstop(triggers.find(t => t === document.activeElement && !t.disabled) || this.activeTrigger || triggers.find(t => !t.disabled));
          this.positionMenus();
          if (this.pendingFocus) {
            const menu = document.getElementById(this.pendingFocus);
            if (menu && this.el.contains(menu)) { this.menuItems(menu)[0]?.focus(); this.pendingFocus = null; }
          }
        },
        positionMenus() {
          for (const menu of this.el.querySelectorAll('[role="menu"]')) {
            const anchor = document.getElementById(menu.getAttribute("aria-labelledby"));
            if (anchor) this.position(menu, anchor);
          }
        },
        position(menu, anchor) {
          const overlay = menu.parentElement;
          const box = anchor.getBoundingClientRect();
          const sub = anchor.dataset.slot === "menubar-sub-trigger";
          const sideOffset = Number(menu.getAttribute("phx-side-offset") || (sub ? 0 : 8));
          const alignOffset = Number(menu.getAttribute("phx-align-offset") || (sub ? 0 : -4));
          const rtl = this.el.getAttribute("phx-dir") === "rtl";
          overlay.style.position = "fixed";
          overlay.style.transform = "none";
          let left = sub ? (rtl ? box.left - overlay.offsetWidth - sideOffset : box.right + sideOffset) : box.left + alignOffset;
          let top = sub ? box.top : box.bottom + sideOffset;
          let side = sub ? (rtl ? "left" : "right") : (menu.getAttribute("phx-side") || "bottom");
          if (!sub && side === "top") top = box.top - overlay.offsetHeight - sideOffset;
          if (!sub && side === "left") { left = box.left - overlay.offsetWidth - sideOffset; top = box.top; }
          if (!sub && side === "right") { left = box.right + sideOffset; top = box.top; }
          if (!sub && (side === "top" || side === "bottom")) {
            const offset = rtl ? -alignOffset : alignOffset;
            const end = (menu.dataset.align === "end") !== rtl;
            left = end ? box.right - overlay.offsetWidth + offset : box.left + offset;
            if (menu.dataset.align === "center") left = box.left + (box.width - overlay.offsetWidth) / 2 + offset;
          } else if (!sub) {
            top = box.top + alignOffset;
            if (menu.dataset.align === "end") top = box.bottom - overlay.offsetHeight + alignOffset;
            if (menu.dataset.align === "center") top = box.top + (box.height - overlay.offsetHeight) / 2 + alignOffset;
          }
          if (side === "bottom" && top + overlay.offsetHeight > window.innerHeight && box.top > overlay.offsetHeight) { top = box.top - overlay.offsetHeight - sideOffset; side = "top"; }
          if (side === "right" && left + overlay.offsetWidth > window.innerWidth && box.left > overlay.offsetWidth) { left = box.left - overlay.offsetWidth - sideOffset; side = "left"; }
          if (side === "left" && left < 0 && window.innerWidth - box.right > overlay.offsetWidth) { left = box.right + sideOffset; side = "right"; }
          left = Math.max(4, Math.min(left, window.innerWidth - overlay.offsetWidth - 4));
          top = Math.max(4, Math.min(top, window.innerHeight - overlay.offsetHeight - 4));
          overlay.style.left = left + "px";
          overlay.style.top = top + "px";
          menu.dataset.side = side;
          menu.style.setProperty("--radix-popper-transform-origin", side === "top" ? "bottom left" : "top left");
          menu.style.setProperty("--radix-popper-available-width", window.innerWidth + "px");
          menu.style.setProperty("--radix-popper-available-height", Math.max(0, window.innerHeight - top) + "px");
          menu.style.setProperty("--radix-popper-anchor-width", box.width + "px");
          menu.style.setProperty("--radix-popper-anchor-height", box.height + "px");
        },
        menuItems(menu) { return [...menu.querySelectorAll('[role^="menuitem"]')].filter(i => !i.hasAttribute("data-disabled") && i.closest('[role="menu"]') === menu); },
        submenu(trigger, open, keyboard) {
          this.pendingFocus = open && keyboard ? trigger.getAttribute("phx-content-id") : null;
          this.sendEvent(trigger.getAttribute("phx-change-event"), {id: trigger.getAttribute("phx-sub-id"), value: open});
        },
        keydown(e) {
          const trigger = e.target.closest('[data-slot="menubar-trigger"]');
          if (trigger && this.el.contains(trigger) && !trigger.disabled) {
            if (["Enter", " ", "ArrowDown"].includes(e.key)) {
              e.preventDefault();
              const close = e.key !== "ArrowDown" && trigger.getAttribute("aria-expanded") === "true";
              this.change(close ? "" : trigger.getAttribute("phx-menu-value"), !close);
              return;
            }
            if (["ArrowLeft", "ArrowRight", "Home", "End"].includes(e.key)) { e.preventDefault(); this.moveTrigger(trigger, e.key, false); }
            return;
          }
          if (!this.owns(e.target)) return;
          const menu = e.target.closest('[role="menu"]');
          const items = this.menuItems(menu);
          if (e.key === "Tab") { this.change("", false); return; }
          if (e.key === "Escape") {
            e.preventDefault();
            const parent = document.getElementById(menu.getAttribute("aria-labelledby"));
            if (parent?.dataset.slot === "menubar-sub-trigger") { this.submenu(parent, false, false); parent.focus(); }
            else { this.change("", false); this.activeTrigger?.focus(); }
            return;
          }
          if (["ArrowLeft", "ArrowRight"].includes(e.key)) {
            e.preventDefault();
            const forward = (e.key === "ArrowRight") !== (this.el.getAttribute("phx-dir") === "rtl");
            if (forward && e.target.dataset.slot === "menubar-sub-trigger") { this.submenu(e.target, true, true); return; }
            const parent = document.getElementById(menu.getAttribute("aria-labelledby"));
            if (!forward && parent?.dataset.slot === "menubar-sub-trigger") { this.submenu(parent, false, false); parent.focus(); return; }
            this.moveTrigger(this.activeTrigger, e.key, true); return;
          }
          if (["Enter", " "].includes(e.key)) { e.preventDefault(); e.target.click(); return; }
          let target;
          if (e.key === "Home") target = items[0];
          else if (e.key === "End") target = items.at(-1);
          else if (e.key === "ArrowDown" || e.key === "ArrowUp") target = items[(items.indexOf(e.target) + (e.key === "ArrowDown" ? 1 : -1) + items.length) % items.length];
          else if (e.key.length === 1 && !e.ctrlKey && !e.metaKey && !e.altKey) {
            clearTimeout(this.typeTimer);
            this.search = (this.search || "") + e.key.toLowerCase();
            if ([...this.search].every(character => character === this.search[0])) this.search = this.search[0];
            this.typeTimer = setTimeout(() => this.search = "", 700);
            target = [...items.slice(items.indexOf(e.target) + 1), ...items].find(i => i.textContent.trim().toLowerCase().startsWith(this.search));
          } else return;
          e.preventDefault(); target?.focus();
        },
        moveTrigger(trigger, key, open) {
          const items = this.triggers().filter(t => !t.disabled);
          let index = key === "Home" ? 0 : key === "End" ? items.length - 1 : items.indexOf(trigger) + (((key === "ArrowRight") !== (this.el.getAttribute("phx-dir") === "rtl")) ? 1 : -1);
          if (this.el.getAttribute("phx-loop") === "true") index = (index + items.length) % items.length;
          const next = items[index];
          if (next) { this.tabstop(next); next.focus(); if (open || this.value) this.change(next.getAttribute("phx-menu-value"), open); }
        },
        beforeUpdate() {
          const focused = document.activeElement;
          this.focusedTrigger = this.el.contains(focused) ? focused.closest('[data-slot="menubar-trigger"]')?.getAttribute("phx-menu-value") : null;
        },
        updated() {
          this.sync();
          if (this.focusedTrigger && document.activeElement === document.body) {
            this.triggers().find(t => t.getAttribute("phx-menu-value") === this.focusedTrigger)?.focus({preventScroll: true});
          }
          this.focusedTrigger = null;
        },
        destroyed() {
          clearTimeout(this.typeTimer);
          document.removeEventListener("click", this.click);
          document.removeEventListener("pointerover", this.pointer);
          document.removeEventListener("pointerdown", this.outside);
          document.removeEventListener("keydown", this.key);
          document.removeEventListener("focusin", this.focus);
          window.removeEventListener("resize", this.layout);
          document.removeEventListener("scroll", this.layout, true);
        }
      }
`
