defmodule Consumer.Shop.Checkout do
  @moduledoc "Shipping details and explicit consent for a local demo order, never card data."
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  @countries [
    {"Finland", "FI"},
    {"Sweden", "SE"},
    {"Denmark", "DK"},
    {"Germany", "DE"},
    {"Netherlands", "NL"}
  ]
  @country_codes Enum.map(@countries, &elem(&1, 1))
  @fields [
    :full_name,
    :email,
    :address,
    :city,
    :postal_code,
    :country,
    :phone,
    :delivery_notes,
    :terms
  ]
  @field_keys Enum.map(@fields, &{&1, Atom.to_string(&1)})
  @unused_keys Enum.map(@field_keys, fn {_field, key} -> "_unused_" <> key end)

  embedded_schema do
    field :full_name, :string
    field :email, :string
    field :address, :string
    field :city, :string
    field :postal_code, :string
    field :country, :string, default: "FI"
    field :phone, :string
    field :delivery_notes, :string
    field :terms, :boolean, default: false
  end

  def countries, do: @countries

  def changeset(attrs \\ %{})

  def changeset(attrs) when is_map(attrs) do
    %__MODULE__{}
    |> cast(normalize_attrs(attrs), @fields)
    |> validate_required([:full_name, :email, :address, :city, :postal_code, :country, :terms])
    |> validate_length(:full_name, min: 2, max: 100)
    |> validate_format(:email, ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/,
      message: "must be a valid email address"
    )
    |> validate_length(:email, max: 254)
    |> validate_length(:address, min: 5, max: 200)
    |> validate_length(:city, min: 2, max: 100)
    |> validate_length(:postal_code, min: 2, max: 20)
    |> validate_inclusion(:country, @country_codes)
    |> validate_postal_code()
    |> validate_length(:phone, max: 40)
    |> validate_format(:phone, ~r/^[+()\d\s.\-]+$/, message: "must contain only a phone number")
    |> validate_length(:delivery_notes, max: 500)
    |> validate_terms()
  end

  def changeset(_attrs),
    do: %__MODULE__{} |> change() |> add_error(:base, "must be a valid checkout form")

  defp normalize_attrs(attrs) do
    # LiveView's input-use metadata controls error display, not schema validation.
    Enum.reduce(@field_keys, Map.take(attrs, @unused_keys), fn {field, key}, result ->
      case Map.fetch(attrs, key) do
        {:ok, value} ->
          Map.put(result, key, normalize_value(field, value))

        :error ->
          case Map.fetch(attrs, field) do
            {:ok, value} -> Map.put(result, key, normalize_value(field, value))
            :error -> result
          end
      end
    end)
  end

  defp normalize_value(:email, value) when is_binary(value),
    do: value |> String.trim() |> String.downcase()

  defp normalize_value(:country, value) when is_binary(value),
    do: value |> String.trim() |> String.upcase()

  defp normalize_value(_field, value) when is_binary(value), do: String.trim(value)
  defp normalize_value(_field, value), do: value

  defp validate_terms(changeset) do
    if get_field(changeset, :terms) == true do
      changeset
    else
      add_error(changeset, :terms, "must be accepted before placing an order")
    end
  end

  defp validate_postal_code(changeset) do
    pattern =
      case get_field(changeset, :country) do
        "FI" -> ~r/^\d{5}$/
        "SE" -> ~r/^\d{3} ?\d{2}$/
        "DK" -> ~r/^\d{4}$/
        "DE" -> ~r/^\d{5}$/
        "NL" -> ~r/^\d{4} ?[A-Za-z]{2}$/
        _country -> nil
      end

    if pattern do
      validate_format(changeset, :postal_code, pattern,
        message: "must be a valid postal code for the selected country"
      )
    else
      changeset
    end
  end
end
