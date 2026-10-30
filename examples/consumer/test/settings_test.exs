defmodule Consumer.SettingsTest do
  use ExUnit.Case, async: true
  alias Consumer.Settings

  test "validates email, name, timezone and bio without a database" do
    changeset =
      Settings.changeset(%Settings{}, %{
        "email" => "not-an-email",
        "display_name" => "A",
        "timezone" => "unsupported",
        "bio" => String.duplicate("x", 281)
      })

    refute changeset.valid?
    assert Keyword.has_key?(changeset.errors, :email)
    assert Keyword.has_key?(changeset.errors, :display_name)
    assert Keyword.has_key?(changeset.errors, :timezone)
    assert Keyword.has_key?(changeset.errors, :bio)
  end

  test "casts the native hidden checkbox false value" do
    changeset = Settings.changeset(%Settings{}, %{"notifications" => "false"})
    assert {:ok, settings} = Ecto.Changeset.apply_action(changeset, :insert)
    refute settings.notifications
  end
end
