import test from "node:test"
import assert from "node:assert/strict"
import { createElement as h, useId, type ReactElement } from "react"
import { compareComponentParity } from "../tools/parity"
import type { ComponentFixture } from "../tools/fixtures"

function fixture(renderReact: () => ReactElement): ComponentFixture {
  return { name: "id-graph", title: "ID graph", category: "forms", renderReact, heex: "" }
}

function GeneratedGraph(): ReactElement {
  const title = `radix-${useId()}`
  const panel = `radix-${useId()}`
  return h("div", null,
    h("button", {
      "aria-controls": panel,
      "aria-labelledby": title,
      "aria-describedby": `${title} help`,
    }, "Open"),
    h("h2", { id: title }, "Title"),
    h("section", { id: panel, "aria-labelledby": title }, "Content"),
    h("p", { id: "help" }, "Help"),
  )
}

const generatedFixture = fixture(() => h(GeneratedGraph))
const generatedHtml = '<div><button aria-controls="radix-panel" aria-labelledby="radix-title" aria-describedby="radix-title help">Open</button><h2 id="radix-title">Title</h2><section id="radix-panel" aria-labelledby="radix-title">Content</section><p id="help">Help</p></div>'

async function expectFailure(component: ComponentFixture, html: string, diagnostic: RegExp): Promise<void> {
  const result = await compareComponentParity(component, html)
  assert.equal(result.passed, false)
  assert.match(result.differences?.join("\n") ?? "", diagnostic)
}

test("generated IDs accept consistent alpha-renaming and forward references", async () => {
  const renamed = generatedHtml.replaceAll("radix-title", "radix-label-72").replaceAll("radix-panel", "radix-content-91")
  const result = await compareComponentParity(generatedFixture, renamed)
  assert.equal(result.passed, true, result.differences?.join("\n"))
  assert.equal(result.differences, undefined)
})

test("a reference to the wrong generated target fails", async () => {
  await expectFailure(generatedFixture,
    generatedHtml.replace('aria-controls="radix-panel"', 'aria-controls="radix-title"'),
    /aria-controls.*value mismatch/)
})

test("swapping generated declarations without updating references fails", async () => {
  await expectFailure(generatedFixture,
    generatedHtml.replace('<h2 id="radix-title"', '<h2 id="radix-panel"')
      .replace('<section id="radix-panel"', '<section id="radix-title"'),
    /aria-controls.*value mismatch/)
})

test("a missing SSR target cannot be equated to a declared target", async () => {
  await expectFailure(generatedFixture, generatedHtml.replace(' id="radix-panel"', ""),
    /aria-controls.*value mismatch/)
})

test("an unmatched generated reference cannot be equated to a declared target", async () => {
  await expectFailure(generatedFixture,
    generatedHtml.replace('aria-controls="radix-panel"', 'aria-controls="radix-missing"'),
    /aria-controls.*value mismatch/)
})


test("all multi-token ARIA reference attributes retain distinct targets", async () => {
  for (const attribute of ["aria-controls", "aria-describedby", "aria-labelledby"]) {
    function MultiReference(): ReactElement {
      const first = `radix-${useId()}`
      const second = `radix-${useId()}`
      return h("div", null,
        h("button", { [attribute]: `${first} ${second}` }, "Open"),
        h("span", { id: first }, "First"),
        h("span", { id: second }, "Second"),
      )
    }
    const component = fixture(() => h(MultiReference))
    const html = `<div><button ${attribute}="radix-first radix-second">Open</button><span id="radix-first">First</span><span id="radix-second">Second</span></div>`
    const result = await compareComponentParity(component, html)
    assert.equal(result.passed, true, result.differences?.join("\n"))
    await expectFailure(component, html.replace(`${attribute}="radix-first radix-second"`, `${attribute}="radix-second radix-first"`),
      new RegExp(`${attribute}.*value mismatch`))
    await expectFailure(component, html.replace(`${attribute}="radix-first radix-second"`, `${attribute}="radix-first"`),
      new RegExp(`${attribute}.*value mismatch`))
  }
})
test("mixed generated and literal reference tokens are compared individually", async () => {
  await expectFailure(generatedFixture,
    generatedHtml.replace('aria-describedby="radix-title help"', 'aria-describedby="radix-title different-help"'),
    /aria-describedby.*value mismatch/)
  await expectFailure(generatedFixture,
    generatedHtml.replace('aria-describedby="radix-title help"', 'aria-describedby="radix-title"'),
    /aria-describedby.*value mismatch/)
})

test("multi-token references preserve token order and repetition", async () => {
  await expectFailure(generatedFixture,
    generatedHtml.replace('aria-describedby="radix-title help"', 'aria-describedby="help radix-title"'),
    /aria-describedby.*value mismatch/)
  await expectFailure(generatedFixture,
    generatedHtml.replace('aria-describedby="radix-title help"', 'aria-describedby="radix-title radix-title"'),
    /aria-describedby.*value mismatch/)
})

test("collapsing distinct generated declarations reports duplicate IDs", async () => {
  await expectFailure(generatedFixture,
    generatedHtml.replaceAll("radix-panel", "radix-title"),
    /duplicate ID "radix-title" in Phoenix/)
})

test("identically duplicated explicit IDs fail even when both documents match", async () => {
  const duplicate = fixture(() => h("div", null, h("span", { id: "duplicate" }), h("span", { id: "duplicate" })))
  const result = await compareComponentParity(duplicate, '<div><span id="duplicate"></span><span id="duplicate"></span></div>')
  assert.equal(result.passed, false)
  const diagnostics = result.differences?.join("\n") ?? ""
  assert.match(diagnostics, /duplicate ID "duplicate" in React/)
  assert.match(diagnostics, /duplicate ID "duplicate" in Phoenix/)
})

test("duplicate generated IDs on the React side are reported independently", async () => {
  function DuplicateGenerated(): ReactElement {
    const id = `radix-${useId()}`
    return h("div", null, h("span", { id }), h("span", { id }))
  }
  await expectFailure(fixture(() => h(DuplicateGenerated)),
    '<div><span id="radix-one"></span><span id="radix-two"></span></div>',
    /duplicate ID .* in React/)
})

function UnmountedGraph(): ReactElement {
  const first = `radix-${useId()}`
  const second = `radix-${useId()}`
  return h("div", null,
    h("button", { "aria-controls": first, "aria-describedby": `${first} ${second}` }, "First"),
    h("button", { "aria-controls": second, "aria-describedby": first }, "Second"),
  )
}

const unmountedFixture = fixture(() => h(UnmountedGraph))
const unmountedHtml = '<div><button aria-controls="radix-hidden" aria-describedby="radix-hidden radix-other">First</button><button aria-controls="radix-other" aria-describedby="radix-hidden">Second</button></div>'

test("generated targets absent in both SSR documents retain their identity graph", async () => {
  const result = await compareComponentParity(unmountedFixture, unmountedHtml)
  assert.equal(result.passed, true, result.differences?.join("\n"))
})

test("collapsing distinct unmounted targets fails without inventing DOM nodes", async () => {
  await expectFailure(unmountedFixture, unmountedHtml.replaceAll("radix-other", "radix-hidden"),
    /aria-describedby.*value mismatch/)
})

test("changing the sharing relationship of unmounted targets fails", async () => {
  await expectFailure(unmountedFixture,
    unmountedHtml.replace('aria-describedby="radix-hidden">Second', 'aria-describedby="radix-other">Second'),
    /aria-describedby.*value mismatch/)
})

test("unmatched literal references are not normalized by a radix substring", async () => {
  const component = fixture(() => h("button", { "aria-controls": "custom-radix-target" }, "Open"))
  await expectFailure(component, '<button aria-controls="custom-radix-other">Open</button>',
    /aria-controls.*value mismatch/)
})

test("caller-supplied references to absent radix-prefixed IDs remain literal", async () => {
  const component = fixture(() => h("button", { "aria-controls": "radix-external-panel" }, "Open"))
  await expectFailure(component, '<button aria-controls="radix-different-panel">Open</button>',
    /aria-controls.*value mismatch/)
})

test("explicit user IDs and references require literal equality", async () => {
  const component = fixture(() => h("div", null,
    h("label", { htmlFor: "email" }, "Email"), h("input", { id: "email" })))
  const same = await compareComponentParity(component, '<div><label for="email">Email</label><input id="email"></div>')
  assert.equal(same.passed, true, same.differences?.join("\n"))
  await expectFailure(component, '<div><label for="renamed">Email</label><input id="renamed"></div>',
    /attribute "(?:for|id)" value mismatch/)
})

test("explicit caller IDs remain literal even when they resemble generated IDs", async () => {
  for (const id of ["radix-explicit", ":r42:", "_R_42_"]) {
    const component = fixture(() => h("div", null,
      h("label", { htmlFor: id }, "Email"), h("input", { id })))
    await expectFailure(component,
      '<div><label for="radix-renamed">Email</label><input id="radix-renamed"></div>',
      /attribute "(?:for|id)" value mismatch/)
  }
})

function NativeGraph(): ReactElement {
  const input = useId()
  const second = useId()
  const form = useId()
  const list = useId()
  const popup = useId()
  return h("div", null,
    h("label", { htmlFor: input }, "Value"),
    h("output", { htmlFor: `${input} ${second}` }, "Result"),
    h("input", { id: input, form, list }),
    h("input", { id: second }),
    h("form", { id: form }),
    h("datalist", { id: list }),
    h("button", { popoverTarget: popup }, "Show"),
    h("a", { href: `#${popup}` }, "Jump"),
    h("div", { id: popup, popover: "auto" }, "Popup"),
  )
}

const nativeHtml = '<div><label for="radix-input">Value</label><output for="radix-input radix-second">Result</output><input id="radix-input" form="radix-form" list="radix-list"><input id="radix-second"><form id="radix-form"></form><datalist id="radix-list"></datalist><button popovertarget="radix-popup">Show</button><a href="#radix-popup">Jump</a><div id="radix-popup" popover="auto">Popup</div></div>'

test("native ID references and bare React useId identities accept consistent renaming", async () => {
  const result = await compareComponentParity(fixture(() => h(NativeGraph)), nativeHtml)
  assert.equal(result.passed, true, result.differences?.join("\n"))
})

test("native references must point at their corresponding generated targets", async () => {
  for (const [reference, wrongReference, attribute] of [
    ['for="radix-input"', 'for="radix-second"', "for"],
    ['for="radix-input radix-second"', 'for="radix-second radix-input"', "for"],
    ['form="radix-form"', 'form="radix-list"', "form"],
    ['list="radix-list"', 'list="radix-form"', "list"],
    ['popovertarget="radix-popup"', 'popovertarget="radix-list"', "popovertarget"],
    ['href="#radix-popup"', 'href="#radix-list"', "href"],
  ]) {
    await expectFailure(fixture(() => h(NativeGraph)), nativeHtml.replace(reference, wrongReference),
      new RegExp(`attribute "${attribute}" value mismatch`))
  }
})
