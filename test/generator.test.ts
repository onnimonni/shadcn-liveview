import test from "node:test"
import assert from "node:assert/strict"
import { parseComponentAST } from "../tools/generate"

test("style metadata without a component declaration fails explicitly instead of fabricating a component", () => {
  const source = `
    import { cva } from "class-variance-authority"
    export const buttonVariants = cva("inline-flex", {
      variants: { variant: { default: "bg-primary" } },
      defaultVariants: { variant: "default" },
    })
  `
  assert.throws(() => parseComponentAST("button", source), error =>
    error instanceof Error && !(error instanceof ReferenceError),
  )
})
