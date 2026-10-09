interface SSRDocument {
  querySelector: (selector: string) => null
  querySelectorAll: (selector: string) => never[]
  createElement: (tagName: string) => { style: Partial<CSSStyleDeclaration> }
  body: { style: Partial<CSSStyleDeclaration> }
  documentElement: { style: Partial<CSSStyleDeclaration> }
}

export function ensureSSRDocument(): void {
  if (typeof globalThis.document !== "undefined") return

  // Vaul reads body.style during SSR. This is a render-only facade, not a DOM:
  // keep window absent, and install it after imports so browser setup stays off.
  const document: SSRDocument = {
    querySelector: () => null,
    querySelectorAll: () => [],
    createElement: () => ({ style: {} }),
    body: { style: {} },
    documentElement: { style: {} },
  }
  Object.defineProperty(globalThis, "document", {
    value: document,
    writable: true,
    configurable: true,
    enumerable: true,
  })
}
