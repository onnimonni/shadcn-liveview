defmodule ShadcnLiveview.IconTest do
  use ExUnit.Case, async: true
  use Phoenix.Component
  import ShadcnLiveview.Components.Icon
  alias Phoenix.HTML.Safe

  test "hero- names render like Phoenix CoreComponents.icon/1" do
    assigns = %{}

    assert render(~H|<.icon name="hero-x-mark" />|) ==
             ~s(<span class="hero-x-mark size-4"></span>)

    assert render(~H|<.icon name="hero-arrow-path" class="ml-1 size-3" />|) ==
             ~s(<span class="hero-arrow-path ml-1 size-3"></span>)
  end

  test "Lucide aliases and PascalCase names resolve to the canonical icon" do
    assigns = %{}
    canonical = render(~H|<.icon name="trash" />|)

    assert canonical =~ ~s(class="lucide lucide-trash lucide-trash-2")
    assert render(~H|<.icon name="trash-2" />|) == canonical
    assert render(~H|<.icon name="Trash2Icon" />|) == canonical
  end

  test "unknown names raise with the supported list and how to request more" do
    assigns = %{}

    error = assert_raise ArgumentError, fn -> render(~H|<.icon name="rocket-ship" />|) end
    message = Exception.message(error)

    assert message =~ ~s(unknown Lucide icon "rocket-ship")
    assert message =~ "layout-dashboard"
    assert message =~ "https://github.com/onnimonni/shadcn-liveview/issues"
  end

  defp render(rendered), do: rendered |> Safe.to_iodata() |> IO.iodata_to_binary()
end
