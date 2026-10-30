defmodule Consumer.Settings do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @timezones ["UTC", "Europe/Helsinki", "America/New_York", "Asia/Tokyo"]

  embedded_schema do
    field :email, :string, default: "alex@example.com"
    field :display_name, :string, default: "Alex Morgan"
    field :timezone, :string, default: "UTC"
    field :notifications, :boolean, default: true
    field :bio, :string, default: "Building useful things with Phoenix LiveView."
  end

  def timezones, do: @timezones

  def changeset(settings, attrs) do
    settings
    |> cast(attrs, [:email, :display_name, :timezone, :notifications, :bio])
    |> validate_required([:email, :display_name, :timezone])
    |> validate_format(:email, ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/,
      message: "must be a valid email address"
    )
    |> validate_length(:email, max: 254)
    |> validate_length(:display_name, min: 2, max: 60)
    |> validate_inclusion(:timezone, @timezones)
    |> validate_length(:bio, max: 280)
  end
end
