import fs from "node:fs/promises";
import path from "node:path";
import esbuild from "esbuild";

async function main() {
  await fs.mkdir("priv/static/assets/css", { recursive: true });
  await fs.mkdir("priv/static/assets/js", { recursive: true });

  // 1. Build CSS via Tailwind CLI module directly in-process
  const savedArgv = process.argv;
  process.argv = [
    "node",
    "tailwindcss",
    "-i",
    "assets/css/app.css",
    "-o",
    "priv/static/assets/css/app.css"
  ];
  await import("../node_modules/@tailwindcss/cli/dist/index.mjs");
  process.argv = savedArgv;

  // 2. Build JS via esbuild API
  const entryJs = "assets/js/app.js";
  const jsExists = await fs.access(entryJs).then(() => true).catch(() => false);
  if (jsExists) {
    await esbuild.build({
      entryPoints: [entryJs],
      bundle: true,
      minify: false,
      format: "esm",
      outfile: "priv/static/assets/js/app.js"
    });
  }

  console.log("Assets built successfully.");
}

main().catch((err) => {
  console.error("Asset build failed:", err);
  process.exit(1);
});
