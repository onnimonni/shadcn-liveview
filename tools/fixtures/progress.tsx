import React from "react"
import type { ComponentFixture } from "../fixtures"
import { Progress } from "../../vendor/shadcn/ui/progress"

// Exercise Radix's runtime normalization even though its max type excludes null.
// An explicit dynamic prop bag preserves the invalid input without a type cast.
const nullMaxProps: Record<string, null> = { max: null }

export const fixtures: ComponentFixture[] = [
  {
    name: "progress",
    title: "Progress",
    category: "feedback",
    renderReact: () => <Progress value={60} className="w-[60%]" />,
    heex: `<.progress value={60} class="w-[60%]" />`
  },
  ...[
    { name: "absent", props: {}, heexAttrs: "" },
    { name: "null", props: { value: null }, heexAttrs: "value={nil}" },
    { name: "zero", props: { value: 0 }, heexAttrs: "value={0}" },
    { name: "fractional", props: { value: 25.5 }, heexAttrs: "value={25.5}" },
    { name: "complete", props: { value: 100 }, heexAttrs: "value={100}" },
    { name: "custom-max", props: { value: 50, max: 200 }, heexAttrs: "value={50} max={200}" },
    { name: "null-max", props: { value: 40, ...nullMaxProps }, heexAttrs: "value={40} max={nil}" },
    { name: "outside-visual-range", props: { value: 125, max: 80 }, heexAttrs: "value={125} max={80}" },
    {
      name: "custom-class-aria",
      props: { value: 75, className: "w-[180px] min-w-24 max-w-64 h-2 bg-primary", id: "upload-progress", "aria-label": "Upload", "aria-valuetext": "Uploading" },
      heexAttrs: 'value={75} class="w-[180px] min-w-24 max-w-64 h-2 bg-primary" id="upload-progress" aria-label="Upload" aria-valuetext="Uploading"'
    },
  ].map(({ name, props, heexAttrs }): ComponentFixture => ({
    name: `progress-${name}`,
    family: "progress",
    title: `Progress ${name}`,
    category: "feedback",
    renderReact: () => <Progress {...props} />,
    heex: `<.progress ${heexAttrs} />`
  })),
]
