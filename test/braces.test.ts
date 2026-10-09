import test from "node:test"
import assert from "node:assert/strict"
import { createRequire } from "node:module"

const braces = createRequire(import.meta.url)("braces")
const maximumDepth = 128
const nested = (open: string, close: string, depth: number) => open.repeat(depth) + "x" + close.repeat(depth)
const depthError = { name: "SyntaxError", message: /AST nesting exceeds maximum depth \(128\)/ }

test("brace and parenthesis parsing reject deep valid-length input before recursive traversal", () => {
  for (const [open, close] of [["{", "}"], ["(", ")"]]) {
    const pattern = nested(open, close, 4000)
    assert.throws(() => braces.parse(pattern), depthError)
    assert.throws(() => braces(pattern), depthError)
    assert.throws(() => braces.expand(pattern), depthError)
  }
})

test("the supported nesting boundary and ordinary expansion retain their behavior", () => {
  const pattern = nested("(", ")", maximumDepth)
  assert.equal(braces.stringify(pattern), pattern)
  assert.equal(braces.compile(pattern), pattern)
  assert.throws(() => braces.parse(nested("(", ")", maximumDepth + 1)), depthError)
  assert.deepEqual(braces.expand("assets/{css,js}/{app,preview}.{css,js}"), [
    "assets/css/app.css", "assets/css/app.js", "assets/css/preview.css", "assets/css/preview.js",
    "assets/js/app.css", "assets/js/app.js", "assets/js/preview.css", "assets/js/preview.js",
  ])
})

interface AstNode {
  type: string
  value?: string
  nodes?: AstNode[]
  parent?: AstNode
}

function deepAst(depth: number): AstNode {
  let node: AstNode = { type: "text", value: "x" }
  for (let index = 0; index < depth; index += 1) {
    const parent: AstNode = { type: "paren", nodes: [node] }
    node.parent = parent
    node = parent
  }
  const root: AstNode = { type: "root", nodes: [node] }
  node.parent = root
  return root
}

test("AST-based compile, expansion and stringify cannot bypass the parser depth limit", () => {
  for (const method of [braces.compile, braces.expand, braces.stringify]) {
    assert.throws(() => method(deepAst(4000)), depthError)
  }
})
