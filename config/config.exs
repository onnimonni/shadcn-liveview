import Config

config :esbuild,
  version: "0.25.12",
  path: Path.expand("../node_modules/.bin/esbuild", __DIR__),
  shadcn_liveview: [
    args:
      ~w(js/app.js --bundle --format=esm --target=es2022 --outdir=../priv/static/assets/js --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ],
  shadcn_liveview_css: [
    args:
      ~w(css/app.css --bundle --conditions=style --loader:.woff2=dataurl --loader:.woff=dataurl --outdir=../priv/static/assets/css),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => [Path.expand("../deps", __DIR__), Mix.Project.build_path()]}
  ]
