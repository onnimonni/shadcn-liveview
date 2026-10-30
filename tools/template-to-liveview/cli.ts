import fs from "node:fs"
import path from "node:path"
import { convertTemplate } from "./convert"
import { findLucide } from "./lucide"
import { findLibDir, loadMetadata } from "./metadata"
import { jsonReport, markdownReport } from "./report"
import { loadPath, loadRegistryItem, type SourceSet } from "./source"

const usage = `Usage: shadcn-to-liveview <input> --module MyAppWeb.LoginLive [options]

Converts a shadcn/ui template (block directory, page/example .tsx file, registry item
JSON file or https://ui.shadcn.com/r/styles/<style>/<name>.json URL) into a Phoenix
LiveView module that uses shadcn_liveview components.

Options:
  --module NAME     Elixir module to generate (required)
  --out FILE        write the module here (default: stdout)
  --report FILE     write the conversion report (.md or .json)
  --json            print the JSON report (including the code) to stdout
  --web MODULE      web module for \`use MODULE, :live_view\` (default: derived from --module)
  --component       generate a function component module instead of a LiveView
  --lib DIR         shadcn_liveview lib/shadcn_liveview dir (default: auto-detected)
  --lucide DIR      lucide-react package used to inline icons missing from icon/1
  -h, --help        show this help
`

interface Args {
  input?: string
  module?: string
  out?: string
  report?: string
  json: boolean
  web?: string
  component: boolean
  lib?: string
  lucide?: string
}

function parseArgs(argv: string[]): Args {
  const args: Args = { json: false, component: false }
  for (let index = 0; index < argv.length; index++) {
    const arg = argv[index]
    const value = () => {
      const next = argv[++index]
      if (next === undefined) throw new Error(`${arg} needs a value`)
      return next
    }
    switch (arg) {
      case "--module": args.module = value(); break
      case "--out": args.out = value(); break
      case "--report": args.report = value(); break
      case "--json": args.json = true; break
      case "--web": args.web = value(); break
      case "--component": args.component = true; break
      case "--lib": args.lib = value(); break
      case "--lucide": args.lucide = value(); break
      case "-h": case "--help": process.stdout.write(usage); process.exit(0)
      default:
        if (arg.startsWith("-")) throw new Error(`unknown option ${arg}`)
        if (args.input) throw new Error(`unexpected argument ${arg}`)
        args.input = arg
    }
  }
  return args
}

async function loadInput(input: string): Promise<SourceSet> {
  if (/^https?:\/\//.test(input)) {
    const response = await fetch(input)
    if (!response.ok) throw new Error(`${input}: HTTP ${response.status}`)
    return loadRegistryItem(await response.text(), path.basename(new URL(input).pathname, ".json"))
  }
  if (input.endsWith(".json")) return loadRegistryItem(fs.readFileSync(input, "utf8"), path.basename(input, ".json"))
  return loadPath(input)
}

export async function main(argv: string[]): Promise<number> {
  let args: Args
  try {
    args = parseArgs(argv)
  } catch (error) {
    process.stderr.write(`${error instanceof Error ? error.message : String(error)}\n\n${usage}`)
    return 2
  }
  if (!args.input || !args.module) {
    process.stderr.write(usage)
    return 2
  }
  if (!/^[A-Z][\w]*(\.[A-Z][\w]*)*$/.test(args.module)) {
    process.stderr.write(`--module must be an Elixir module name, got ${args.module}\n`)
    return 2
  }
  const set = await loadInput(args.input)
  const meta = loadMetadata(findLibDir(args.lib))
  const lucide = findLucide(args.lucide, [process.cwd(), ...set.roots])
  const result = convertTemplate(set, meta, { module: args.module, web: args.web, mode: args.component ? "component" : "live", lucide })
  if (args.out) {
    fs.mkdirSync(path.dirname(path.resolve(args.out)), { recursive: true })
    fs.writeFileSync(args.out, result.code)
  }
  if (args.report) {
    fs.mkdirSync(path.dirname(path.resolve(args.report)), { recursive: true })
    fs.writeFileSync(args.report, args.report.endsWith(".json") ? jsonReport(result, args.out) : markdownReport(result, args.out))
  }
  if (args.json) process.stdout.write(jsonReport(result, args.out))
  else if (!args.out) process.stdout.write(result.code)
  process.stderr.write(`${result.label}: ${result.module}${args.out ? ` → ${args.out}` : ""}; ${result.todos.length} TODO(s), ${result.skipped.length} skipped source part(s), ${result.notes.length} note(s)${args.report ? `; report: ${args.report}` : ""}\n`)
  return 0
}

main(process.argv.slice(2)).then(code => process.exit(code), error => {
  process.stderr.write(`shadcn-to-liveview: ${error instanceof Error ? error.message : String(error)}\n`)
  process.exit(1)
})
