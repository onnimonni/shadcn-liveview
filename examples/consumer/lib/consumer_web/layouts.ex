defmodule ConsumerWeb.Layouts do
  use Phoenix.Component

  def root(assigns) do
    assigns = assign_new(assigns, :page_title, fn -> "Northline · shadcn LiveView consumer" end)

    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="csrf-token" content={Phoenix.Controller.get_csrf_token()} />
        <title>{@page_title}</title>
        <link rel="stylesheet" href="/shadcn/shadcn.css" />
        <link rel="stylesheet" href={ConsumerWeb.Endpoint.static_path("/assets/consumer.css")} />
        <link rel="stylesheet" href={ConsumerWeb.Endpoint.static_path("/assets/shop.css")} />
        <link rel="stylesheet" href={ConsumerWeb.Endpoint.static_path("/assets/shop-catalog.css")} />
        <link rel="stylesheet" href={ConsumerWeb.Endpoint.static_path("/assets/shop-checkout.css")} />
        <script type="module" src={ConsumerWeb.Endpoint.static_path("/assets/app.js")}>
        </script>
      </head>
      <body class="bg-background text-foreground">
        {@inner_content}
      </body>
    </html>
    """
  end
end

defmodule ConsumerWeb.ErrorHTML do
  def render(template, _assigns), do: Phoenix.Controller.status_message_from_template(template)
end
