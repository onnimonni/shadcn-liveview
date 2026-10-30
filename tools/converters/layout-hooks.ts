import { sendEventMethod } from "./hook-events"

// Carousel, resizable and sidebar state is client-owned; their pushes only notify the server.
const targetAwareHookPreamble = `      export default {
${sendEventMethod("        ")}`

export const carouselHook = `      import EmblaCarousel from "embla-carousel";
${targetAwareHookPreamble}
        mounted() {
          this.abort = new AbortController();
          const on = (name, callback, options = {}) => this.el.addEventListener(name, callback, {...options, signal: this.abort.signal});
          this.selected = () => {
            const focused = this.el.contains(document.activeElement) ? document.activeElement : null;
            this.syncControls();
            const index = this.api.selectedScrollSnap();
            this.el.dispatchEvent(new CustomEvent("carousel:select", {detail: {index}, bubbles: true}));
            this.sendEvent("shadcn:carousel-change", {id: this.el.id, value: index}, () => this.restoreFocus(focused));
          };
          on("click", event => {
            const button = event.target.closest('[data-slot="carousel-previous"], [data-slot="carousel-next"]');
            if (!this.api || !button || button.closest('[data-slot="carousel"]') !== this.el || button.disabled) return;
            if (button.getAttribute("data-slot") === "carousel-next") this.api.scrollNext();
            else this.api.scrollPrev();
          });
          on("keydown", event => {
            if (!this.api || event.key !== "ArrowLeft" && event.key !== "ArrowRight") return;
            event.preventDefault();
            if (event.key === "ArrowRight") this.api.scrollNext();
            else this.api.scrollPrev();
          }, {capture:true});
          this.configure();
        },
        configure() {
          const viewport = [...this.el.querySelectorAll('[data-slot="carousel-content"]')].find(node => node.closest('[data-slot="carousel"]') === this.el);
          if (!viewport) { this.api?.destroy(); this.api = null; this.viewport = null; return; }
          const axis = this.el.getAttribute("phx-value-orientation") === "vertical" ? "y" : "x";
          const loop = this.el.getAttribute("phx-value-loop") === "true";
          const serverIndex = Number(this.el.getAttribute("phx-value-start-index") || 0);
          const selected = this.api?.selectedScrollSnap() ?? serverIndex;
          const startIndex = serverIndex !== this.serverIndex ? serverIndex : selected;
          if (!this.api || viewport !== this.viewport) {
            this.api?.destroy();
            this.viewport = viewport;
            this.api = EmblaCarousel(viewport, {axis, loop, startIndex});
            this.api.on("select", this.selected).on("reInit", () => this.syncControls());
          } else if (axis !== this.axis || loop !== this.loop || startIndex !== selected || this.api.containerNode() !== viewport.firstElementChild) {
            this.api.reInit({axis, loop, startIndex});
          }
          this.axis = axis; this.loop = loop; this.serverIndex = serverIndex;
          this.syncControls();
        },
        syncControls() {
          this.el.querySelectorAll('[data-slot="carousel-previous"], [data-slot="carousel-next"]').forEach(button => {
            if (button.closest('[data-slot="carousel"]') !== this.el) return;
            const canScroll = button.getAttribute("data-slot") === "carousel-previous" ? this.api.canScrollPrev() : this.api.canScrollNext();
            button.disabled = button.getAttribute("phx-value-disabled") === "true" || !canScroll;
          });
        },
        restoreFocus(focused) {
          if (!focused || document.activeElement !== document.body) return;
          const slot = focused.getAttribute("data-slot");
          const replacement = slot && this.el.querySelector('[data-slot="' + slot + '"]');
          const target = focused.isConnected && !focused.disabled ? focused : replacement && !replacement.disabled ? replacement : null;
          target?.focus({preventScroll:true});
        },
        beforeUpdate() {
          // HEEx does not render Embla-owned track and loop-slide transforms.
          this.transforms = this.api ? [this.api.containerNode(), ...this.api.slideNodes()].map(node => [node, node.style.transform]) : [];
        },
        updated() {
          for (const [node, transform] of this.transforms || []) if (node.isConnected) node.style.transform = transform;
          this.transforms = null;
          this.configure();
        },
        destroyed() { this.abort.abort(); this.api?.destroy(); }
      }`

export const resizableHook = `${targetAwareHookPreamble}
        mounted() {
          this.abort = new AbortController();
          const on = (name, callback) => this.el.addEventListener(name, callback, {signal: this.abort.signal});
          on("pointerdown", event => {
            const handle = event.target.closest('[data-slot="resizable-handle"]');
            if (event.button !== 0 || !this.usable(handle)) return;
            event.preventDefault(); handle.setPointerCapture(event.pointerId);
            this.drag = {handle, id: event.pointerId, start: this.point(event), sizes: this.sizes()};
            handle.dataset.separator = "active";
          });
          on("pointermove", event => { if (this.drag && this.drag.id === event.pointerId) this.resize(this.drag.handle, this.drag.sizes, (this.point(event) - this.drag.start) / this.length() * 100); });
          const end = event => {
            if (!this.drag || this.drag.id !== event.pointerId) return;
            this.drag.handle.dataset.separator = "inactive"; this.drag = null; this.emit();
          };
          on("pointerup", end); on("pointercancel", end); on("lostpointercapture", end);
          on("dblclick", event => {
            const handle = event.target.closest('[data-slot="resizable-handle"]');
            if (event.defaultPrevented || !this.usable(handle) || handle.getAttribute("phx-value-disable-double-click") === "true") return;
            const panels = this.panels(), index = this.pair(handle).find(index => panels[index].hasAttribute("phx-value-default-size"));
            if (index === undefined) return;
            event.preventDefault(); this.reset(index);
          });
          on("keydown", event => {
            const handle = event.target.closest('[data-slot="resizable-handle"]');
            if (!this.usable(handle)) return;
            const keys = this.vertical() ? ["ArrowUp", "ArrowDown"] : ["ArrowLeft", "ArrowRight"];
            let delta = event.key === keys[0] ? -5 : event.key === keys[1] ? 5 : 0;
            if (event.key === "Home") delta = -100;
            if (event.key === "End") delta = 100;
            if (!delta) return;
            event.preventDefault(); this.resize(handle, this.sizes(), delta); this.emit();
          });
          this.observer = new ResizeObserver(() => this.aria()); this.observer.observe(this.el); this.configure();
        },
        vertical() { return this.el.getAttribute("phx-value-orientation") === "vertical"; },
        point(event) { return this.vertical() ? event.clientY : event.clientX; },
        length() { return this.panels().reduce((total,panel) => total + (this.vertical() ? panel.offsetHeight : panel.offsetWidth), 0); },
        panels() { return [...this.el.children].filter(node => node.dataset.slot === "resizable-panel"); },
        handles() { return [...this.el.children].filter(node => node.dataset.slot === "resizable-handle"); },
        sizes() { const sizes = this.panels().map(node => this.vertical() ? node.getBoundingClientRect().height : node.getBoundingClientRect().width); const total = sizes.reduce((a,b) => a+b, 0); return sizes.map(size => total ? size / total * 100 : 100 / sizes.length); },
        bound(panel, name, fallback) {
          const value = panel.getAttribute("phx-value-" + name);
          if (!value) return fallback;
          if (value.endsWith("%")) return parseFloat(value);
          let pixels;
          if (/^[\\d.]+(?:px)?$/.test(value)) pixels = parseFloat(value);
          else {
            const probe = document.createElement("div"); probe.style.position = "absolute"; probe.style.visibility = "hidden"; probe.style[this.vertical() ? "height" : "width"] = value;
            this.el.append(probe); pixels = this.vertical() ? probe.getBoundingClientRect().height : probe.getBoundingClientRect().width; probe.remove();
          }
          return this.length() ? pixels / this.length() * 100 : fallback;
        },
        pair(handle) {
          const panels = this.panels(); return [panels.indexOf(handle.previousElementSibling), panels.indexOf(handle.nextElementSibling)];
        },
        usable(handle) {
          if (!handle || handle.parentElement !== this.el || handle.getAttribute("aria-disabled") === "true" || this.el.getAttribute("phx-value-disabled") === "true") return false;
          const [left,right] = this.pair(handle); const panels = this.panels();
          return left >= 0 && right >= 0 && ![panels[left],panels[right]].some(panel => panel.dataset.disabled === "true" || this.bound(panel, "min-size", 0) >= this.bound(panel, "max-size", 100));
        },
        resize(handle, sizes, delta) {
          const [a,b] = this.pair(handle); const panels = this.panels(); const total = sizes[a] + sizes[b];
          const minA = this.bound(panels[a], "min-size", 0), minB = this.bound(panels[b], "min-size", 0);
          const maxA = this.bound(panels[a], "max-size", 100), maxB = this.bound(panels[b], "max-size", 100);
          const collapsedA = panels[a].getAttribute("phx-value-collapsible") === "true" ? this.bound(panels[a], "collapsed-size", 0) : minA;
          const collapsedB = panels[b].getAttribute("phx-value-collapsible") === "true" ? this.bound(panels[b], "collapsed-size", 0) : minB;
          const low = Math.max(collapsedA, total - maxB), high = Math.min(maxA, total - collapsedB);
          if (low > high) return;
          let value = Math.max(low, Math.min(high, sizes[a] + delta));
          if (value < minA) value = value < (minA + collapsedA) / 2 ? collapsedA : minA;
          if (total - value < minB) value = total - (total - value < (minB + collapsedB) / 2 ? collapsedB : minB);
          value = Math.max(low, Math.min(high, value));
          const next = [...sizes]; next[a] = value; next[b] = total - value;
          panels.forEach((panel,index) => { panel.style.flexBasis = "0px"; panel.style.flexGrow = next[index]; panel.style.flexShrink = "1"; }); this.aria();
        },
        clamp(panel, value) {
          const min = this.bound(panel, "min-size", 0), max = this.bound(panel, "max-size", 100);
          if (value < min) {
            const collapsed = this.bound(panel, "collapsed-size", 0);
            value = panel.getAttribute("phx-value-collapsible") === "true" && value < (min + collapsed) / 2 ? collapsed : min;
          }
          return Math.min(max, value);
        },
        normalize(values) {
          const panels = this.panels(), total = values.reduce((sum,value) => sum + value, 0);
          const normalized = values.map(value => total ? value / total * 100 : 100 / panels.length);
          let remaining = 0;
          panels.forEach((panel,index) => { const next = this.clamp(panel, normalized[index]); remaining += normalized[index] - next; normalized[index] = next; });
          for (let index = 0; index < panels.length && Math.abs(remaining) > .001; index++) {
            const next = this.clamp(panels[index], normalized[index] + remaining);
            remaining -= next - normalized[index]; normalized[index] = next;
          }
          return normalized;
        },
        apply(values) {
          this.panels().forEach((panel,index) => {panel.style.flexBasis="0px";panel.style.flexGrow=values[index];panel.style.flexShrink="1";}); this.aria();
        },
        reset(index) {
          const panels = this.panels(), sizes = this.sizes(), last = index === panels.length - 1;
          const target = this.bound(panels[index], "default-size", sizes[index]);
          let delta = last ? sizes[index] - target : target - sizes[index];
          if (Math.abs(delta) < .001) return;
          const a = last ? index - 1 : index, b = last ? index : index + 1;
          const expanding = delta > 0 ? a : b, min = this.bound(panels[expanding], "min-size", 0);
          if (panels[expanding].getAttribute("phx-value-collapsible") === "true" && sizes[expanding] < min && sizes[expanding] + Math.abs(delta) < min) {
            const gap = min - this.bound(panels[expanding], "collapsed-size", 0);
            if (Math.abs(delta) < gap / 2 || (Math.abs(delta) === gap / 2 && delta > 0)) return;
            delta = delta < 0 ? -gap : gap;
          }
          const growing = [], shrinking = [];
          for (let current = delta > 0 ? a : b; current >= 0 && current < panels.length; current += delta > 0 ? -1 : 1) growing.push(current);
          for (let current = delta > 0 ? b : a; current >= 0 && current < panels.length; current += delta > 0 ? 1 : -1) shrinking.push(current);
          const clamp = (current,value) => panels[current].dataset.disabled === "true" ? sizes[current] : this.clamp(panels[current], value);
          const capacity = growing.reduce((sum,current) => sum + clamp(current,100) - sizes[current], 0);
          const requested = Math.min(Math.abs(delta), Math.max(0,capacity)), next = [...sizes];
          let freed = 0;
          for (const current of shrinking) {
            next[current] = clamp(current, sizes[current] - (requested - freed));
            freed += sizes[current] - next[current];
            if (freed >= requested - .001) break;
          }
          let remaining = freed;
          for (const current of growing) {
            next[current] = clamp(current, sizes[current] + remaining);
            remaining -= next[current] - sizes[current];
            if (Math.abs(remaining) < .001) break;
          }
          if (Math.abs(remaining) > .1 || next.every((value,current) => Math.abs(value - sizes[current]) < .001)) return;
          this.apply(next); this.emit();
        },
        configure() {
          const panels = this.panels(), values = this.sizes(), layoutValue = this.el.getAttribute("phx-value-layout");
          const signature = [this.vertical(),layoutValue,panels.map(panel => [panel.id,...["default-size","min-size","max-size","collapsible","collapsed-size"].map(name => panel.getAttribute("phx-value-"+name))].join(":")).join("|")].join(";");
          if (signature === this.layoutSignature) {this.aria();return;} this.layoutSignature = signature;
          const defaults = panels.map(panel => panel.getAttribute("phx-value-default-size") ? this.bound(panel, "default-size", 0) : null);
          const specified = defaults.reduce((sum,value) => sum + (value || 0), 0), missing = defaults.filter(value => value === null).length;
          if (defaults.some(value => value !== null)) {
            const requested = defaults.map(value => value === null ? Math.max(0,100-specified) / missing : value);
            const sum = requested.reduce((total,value) => total + value,0);
            if (sum) requested.forEach((value,index) => {values[index] = value / sum * 100;});
          }
          if (layoutValue) {
            const layout = JSON.parse(layoutValue);
            if (panels.every(panel => typeof layout[panel.id] === "number")) panels.forEach((panel,index) => {values[index] = layout[panel.id];});
          }
          this.apply(this.normalize(values));
        },
        aria() {
          if (!this.length()) return;
          const panels = this.panels(), sizes = this.sizes();
          this.handles().forEach(handle => {
            const [a,b] = this.pair(handle); if (a < 0 || b < 0) return;
            handle.setAttribute("aria-controls", panels[a].id);
            handle.setAttribute("aria-valuemin", String(Math.round(this.bound(panels[a], "min-size", 0))));
            handle.setAttribute("aria-valuemax", String(Math.round(this.bound(panels[a], "max-size", 100))));
            handle.setAttribute("aria-valuenow", String(Math.round(sizes[a])));
          });
        },
        emit() {
          const sizes = this.sizes(), value = Object.fromEntries(this.panels().map((panel,index) => [panel.id, sizes[index]]));
          this.el.dispatchEvent(new CustomEvent("resizable:change", {detail:value,bubbles:true}));
          this.sendEvent("shadcn:resizable-change", {id:this.el.id,value});
        },
        updated() { this.configure(); },
        destroyed() { this.abort.abort(); this.observer.disconnect(); this.drag = null; }
      }`

// Upstream SheetOverlay classes (vendor/shadcn/ui/sheet.tsx): the mobile sidebar is a Sheet upstream.
export const sheetOverlayClasses = "fixed inset-0 z-50 bg-black/10 duration-100 supports-backdrop-filter:backdrop-blur-xs data-open:animate-in data-open:fade-in-0 data-closed:animate-out data-closed:fade-out-0"

export const sidebarHook = `${targetAwareHookPreamble}
        mounted() {
          this.abort = new AbortController(); this.open = this.el.getAttribute("phx-value-open") === "true"; this.serverOpen = this.open;
          this.serverMobileOpen = this.el.getAttribute("phx-value-mobile-open") === "true"; this.mobileOpen = this.serverMobileOpen;
          this.original = new WeakMap();
          this.media = matchMedia("(max-width: 767px)");
          this.mobileOpen = this.mobileOpen && this.media.matches;
          const on = (target,name,fn) => target.addEventListener(name,fn,{signal:this.abort.signal});
          on(this.el,"click",event => {
            const trigger = event.target.closest('[data-sidebar="trigger"],[data-sidebar="rail"]');
            if (trigger && trigger.closest('[data-slot="sidebar-wrapper"]') === this.el) this.toggle(trigger);
          });
          on(document,"sidebar:mobile-open",event => {if(event.detail.id!==this.el.id) this.closeMobile();});
          on(document,"keydown",event => {
            if (event.key.toLowerCase() === "b" && (event.ctrlKey || event.metaKey)) {
              const owner = document.activeElement?.closest('[data-slot="sidebar-wrapper"]') || document.querySelector('[data-slot="sidebar-wrapper"]');
              if (owner === this.el) { event.preventDefault(); this.toggle(document.activeElement); }
            }
            if (!this.mobileOpen) return;
            const container = this.containers()[0]; if (!container) return;
            // Escape belongs to the innermost layer: a popup opened from the sheet closes first (it marks
            // the event handled when focused; otherwise its own document listener closes it).
            if (event.key === "Escape" && !event.defaultPrevented && !this.popups(container).length) { event.preventDefault(); this.closeMobile(); }
            if (event.key === "Tab") {
              const targets = [...container.querySelectorAll('button:not(:disabled),a[href],input:not(:disabled),select:not(:disabled),textarea:not(:disabled),[tabindex="0"]')].filter(node => node.getClientRects().length);
              const first = targets[0] || container, last = targets[targets.length-1] || container;
              if (event.shiftKey && (document.activeElement === first || document.activeElement === container)) { event.preventDefault(); last.focus(); }
              else if (!event.shiftKey && (document.activeElement === last || !this.owns(container, document.activeElement))) { event.preventDefault(); first.focus(); }
            }
          });
          on(this.media,"change",() => { this.closeMobile(); this.paint(); });
          this.paint();
        },
        roots() { return [...this.el.querySelectorAll('[data-slot="sidebar"]')].filter(node => node.closest('[data-slot="sidebar-wrapper"]') === this.el && node.hasAttribute("data-collapsible")); },
        containers() { return this.roots().map(root => root.querySelector('[data-slot="sidebar-container"]')); },
        // Open popup contents whose triggers live in the sheet; their focus counts as inside the sheet.
        popups(container) { return [...container.querySelectorAll("[phx-popup-content-id]")].map(trigger => document.getElementById(trigger.getAttribute("phx-popup-content-id"))).filter(Boolean); },
        owns(container, node) { return Boolean(node) && node !== document.body && (container.contains(node) || this.popups(container).some(content => content.contains(node))); },
        closeMobile() {
          if (!this.mobileOpen) return;
          this.mobileOpen = false; this.sendEvent("shadcn:sidebar-change", {id:this.el.id+"-mobile",open:false}); this.paint();
        },
        toggle(trigger) {
          if (this.media.matches) {
            this.returnFocus = trigger; this.mobileOpen = !this.mobileOpen;
            if(this.mobileOpen) document.dispatchEvent(new CustomEvent("sidebar:mobile-open",{detail:{id:this.el.id}}));
            this.sendEvent("shadcn:sidebar-change", {id:this.el.id+"-mobile",open:this.mobileOpen});
          } else {
            this.open = !this.open; document.cookie = "sidebar_state=" + this.open + "; path=/; max-age=604800";
            this.sendEvent("shadcn:sidebar-change", {id:this.el.id,open:this.open});
          }
          this.paint(); this.el.dispatchEvent(new CustomEvent("sidebar:change", {detail:{open:this.open, mobileOpen:this.mobileOpen},bubbles:true}));
        },
        paint() {
          const mobile = this.media.matches;
          (this.inertNodes || []).forEach(node => node.removeAttribute("inert")); this.inertNodes = [];
          this.roots().forEach(root => {
            const container = root.querySelector('[data-slot="sidebar-container"]');
            const mode = root.getAttribute("phx-value-collapsible") || "offcanvas";
            root.dataset.state = mobile || this.open ? "expanded" : "collapsed"; root.dataset.collapsible = mobile || this.open ? "" : mode;
            if (!container) return;
            if (!this.original.has(container)) this.original.set(container,Object.fromEntries(["role","aria-modal","aria-label","tabindex","data-mobile","style"].map(name => [name,container.getAttribute(name)])));
            if (mobile) {
              root.style.display = this.mobileOpen ? "block" : "none";
              root.querySelector('[data-slot="sidebar-gap"]').style.display = "none";
              container.style.cssText = (this.original.get(container).style || "") + ";display:flex;position:fixed;top:0;bottom:0;width:18rem;max-width:calc(100vw - 2rem);z-index:51;" + (root.dataset.side === "right" ? "right:0;left:auto;" : "left:0;right:auto;");
              container.setAttribute("role","dialog"); container.setAttribute("aria-modal","true"); container.setAttribute("aria-label","Sidebar"); container.setAttribute("tabindex","-1"); container.dataset.mobile = "true";
              container.style.setProperty("--sidebar-width", "18rem");
            } else {
              root.style.removeProperty("display");
              root.querySelector('[data-slot="sidebar-gap"]').style.removeProperty("display");
              Object.entries(this.original.get(container)).forEach(([name,value]) => {if(value===null) container.removeAttribute(name);else container.setAttribute(name,value);});
              if (!this.open && mode === "offcanvas") this.hideOffcanvas(container);
            }
          });
          this.el.querySelectorAll('[data-sidebar="trigger"],[data-sidebar="rail"]').forEach(trigger => {
            if (trigger.closest('[data-slot="sidebar-wrapper"]') !== this.el) return;
            const target = this.containers()[0]; if (target) trigger.setAttribute("aria-controls",target.id);
            trigger.setAttribute("aria-expanded",String(mobile ? this.mobileOpen : this.open));
            // Upstream's trigger has no expanded state, so its ghost button never paints aria-expanded:* styles.
            if (trigger.dataset.sidebar === "trigger") trigger.classList.remove(...[...trigger.classList].filter(name => name.startsWith("aria-expanded:")));
          });
          const opening = mobile && this.mobileOpen && !this.backdrop;
          if (opening) {
            // Upstream renders the mobile sidebar inside a Sheet; reuse its overlay styles.
            this.backdrop = document.createElement("div"); this.backdrop.dataset.state = "open";
            this.backdrop.className = ${JSON.stringify(sheetOverlayClasses)};
            this.backdrop.addEventListener("click",() => this.closeMobile(),{signal:this.abort.signal});
            this.el.append(this.backdrop);
            this.locked = true; this.previousOverflow = document.body.style.overflow; document.body.style.overflow = "hidden";
          } else if (mobile && this.mobileOpen && !this.backdrop.isConnected) {
            this.el.append(this.backdrop);
          } else if ((!mobile || !this.mobileOpen) && this.backdrop) {
            this.backdrop.remove(); this.backdrop=null; this.unlock(); this.returnFocus?.focus();
          }
          if (mobile && this.mobileOpen) {
            // Focus the sheet when it opens or when a patch dropped focus to the body; never take
            // focus from the sheet's own popups or from other layers opened on top of it.
            const container = this.containers()[0], active = document.activeElement;
            if (container && (opening || !active || active === document.body) && !this.owns(container, active)) container.focus();
          }
        },
        hideOffcanvas(container) {
          // A collapsed offcanvas sidebar sits off-screen: keep its contents out of the tab order and
          // accessibility tree. The rail stays live because it peeks in from the edge to expand it.
          const rails = [...container.querySelectorAll('[data-sidebar="rail"]')];
          if (container.contains(document.activeElement) && !rails.includes(document.activeElement)) {
            const trigger = [...this.el.querySelectorAll('[data-sidebar="trigger"]')].find(node => node.closest('[data-slot="sidebar-wrapper"]') === this.el && !container.contains(node) && node.getClientRects().length);
            trigger ? trigger.focus() : document.activeElement.blur();
          }
          const hide = node => [...node.children].forEach(child => {
            if (rails.includes(child)) return;
            if (rails.some(rail => child.contains(rail))) hide(child);
            else if (!child.hasAttribute("inert")) { child.setAttribute("inert",""); this.inertNodes.push(child); }
          });
          hide(container);
        },
        unlock() { if (this.locked) { document.body.style.overflow=this.previousOverflow;this.locked=false; } },
        beforeUpdate() { this.backdrop?.remove(); },
        updated() {
          const state=this.el.getAttribute("phx-value-open")==="true"; if(state!==this.serverOpen){this.open=state;this.serverOpen=state;}
          const mobileState=this.el.getAttribute("phx-value-mobile-open")==="true"; if(mobileState!==this.serverMobileOpen){this.mobileOpen=mobileState&&this.media.matches;this.serverMobileOpen=mobileState;}
          this.paint();
        },
        destroyed() { this.abort.abort();this.backdrop?.remove();this.unlock(); }
      }`
