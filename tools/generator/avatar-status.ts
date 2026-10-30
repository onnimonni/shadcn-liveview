// Radix AvatarImage renders nothing until its probe image loads, and AvatarFallback
// renders until then (and after an error). Phoenix renders the <img> so the browser
// loads it; this side-effect module (no hook, so no id is required) mirrors the load
// status into data-status="loading|loaded|error", which the library CSS uses to show
// the image and hide the fallback only once loaded. A MutationObserver re-applies the
// status after LiveView patches drop the client-owned attribute and tracks src changes.
export const avatarStatusScript = String.raw`
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
`
