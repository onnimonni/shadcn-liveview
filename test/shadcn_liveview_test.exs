defmodule ShadcnLiveviewTest do
  use ExUnit.Case, async: true
  use Phoenix.Component
  use ShadcnLiveview

  test "renders button component with variant and size" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.button variant="default" size="default">Click me</.button>
      """)

    assert html =~ ~s(data-slot="button")
    assert html =~ ~s(data-variant="default")
    assert html =~ ~s(data-size="default")
    assert html =~ "Click me"
  end

  test "renders badge component" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.badge variant="secondary">New</.badge>
      """)

    assert html =~ ~s(data-slot="badge")
    assert html =~ ~s(data-variant="secondary")
    assert html =~ "New"
  end

  test "renders card compound component" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.card>
        <.card_header>
          <.card_title>Title</.card_title>
          <.card_description>Description</.card_description>
        </.card_header>
        <.card_content>Body</.card_content>
      </.card>
      """)

    assert html =~ ~s(data-slot="card")
    assert html =~ ~s(data-slot="card-header")
    assert html =~ ~s(data-slot="card-title")
    assert html =~ ~s(data-slot="card-description")
    assert html =~ ~s(data-slot="card-content")
  end

  test "gallery renders all 61 fixtures to valid HTML" do
    names = ShadcnLiveview.Gallery.names()
    assert length(names) == 61

    for name <- names do
      html = ShadcnLiveview.Gallery.render_html(name)
      assert is_binary(html), "Expected HTML string for fixture #{name}"
      assert String.length(html) > 0, "Expected non-empty HTML for fixture #{name}"
    end
  end

  defp rendered_to_string(rendered) do
    rendered
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
  end
end
