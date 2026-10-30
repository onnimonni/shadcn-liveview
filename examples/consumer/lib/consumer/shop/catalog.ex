defmodule Consumer.Shop.Catalog do
  @moduledoc "The curated Northline catalog. Prices are integer euro cents; stock is seeded by Store."

  @categories ["Clothing", "Bags", "Home", "Accessories"]
  @products [
    %{
      id: "field-jacket",
      slug: "field-jacket",
      name: "Field Jacket",
      category: "Clothing",
      description:
        "A dependable layer for changing skies. Cut from sturdy organic cotton with roomy patch pockets and an easy, unstructured fit.",
      price_cents: 12_900,
      image: "/assets/products/field-jacket.svg",
      badge: "New",
      material: "100% organic cotton twill",
      variants: [
        %{
          id: "field-jacket-moss-small",
          label: "Moss / Small",
          color: "#586b4d",
          size: "Small",
          stock: 6
        },
        %{
          id: "field-jacket-moss-medium",
          label: "Moss / Medium",
          color: "#586b4d",
          size: "Medium",
          stock: 8
        },
        %{
          id: "field-jacket-moss-large",
          label: "Moss / Large",
          color: "#586b4d",
          size: "Large",
          stock: 4
        },
        %{
          id: "field-jacket-clay-medium",
          label: "Clay / Medium",
          color: "#aa8067",
          size: "Medium",
          stock: 2
        }
      ]
    },
    %{
      id: "everyday-tee",
      slug: "everyday-tee",
      name: "Everyday Tee",
      category: "Clothing",
      description:
        "Your everyday starting point. Soft, substantial jersey with a relaxed silhouette and a neckline made to hold its shape.",
      price_cents: 2_900,
      image: "/assets/products/everyday-tee.svg",
      badge: "Bestseller",
      material: "100% organic cotton jersey",
      variants: [
        %{
          id: "everyday-tee-chalk-small",
          label: "Chalk / Small",
          color: "#e8e2d5",
          size: "Small",
          stock: 12
        },
        %{
          id: "everyday-tee-chalk-medium",
          label: "Chalk / Medium",
          color: "#e8e2d5",
          size: "Medium",
          stock: 14
        },
        %{
          id: "everyday-tee-chalk-large",
          label: "Chalk / Large",
          color: "#e8e2d5",
          size: "Large",
          stock: 10
        },
        %{
          id: "everyday-tee-ink-medium",
          label: "Ink / Medium",
          color: "#303c42",
          size: "Medium",
          stock: 10
        }
      ]
    },
    %{
      id: "canvas-tote",
      slug: "canvas-tote",
      name: "Canvas Tote",
      category: "Bags",
      description:
        "From the market to the morning commute. A generous carryall with reinforced handles, an inside pocket, and a flat base that stands on its own.",
      price_cents: 4_900,
      image: "/assets/products/canvas-tote.svg",
      badge: "Bestseller",
      material: "Heavyweight recycled cotton canvas",
      variants: [
        %{
          id: "canvas-tote-natural",
          label: "Natural / One size",
          color: "#d8c9aa",
          size: "One size",
          stock: 9
        },
        %{
          id: "canvas-tote-forest",
          label: "Forest / One size",
          color: "#315145",
          size: "One size",
          stock: 6
        }
      ]
    },
    %{
      id: "weekend-duffel",
      slug: "weekend-duffel",
      name: "Weekend Duffel",
      category: "Bags",
      description:
        "Pack a little, go a long way. A compact weekend bag with a wide zip opening, comfortable webbing handles, and a detachable shoulder strap.",
      price_cents: 8_900,
      image: "/assets/products/weekend-duffel.svg",
      badge: nil,
      material: "Recycled cotton canvas with cotton webbing",
      variants: [
        %{
          id: "weekend-duffel-olive",
          label: "Olive / One size",
          color: "#6f7550",
          size: "One size",
          stock: 5
        },
        %{
          id: "weekend-duffel-midnight",
          label: "Midnight / One size",
          color: "#28363d",
          size: "One size",
          stock: 1
        }
      ]
    },
    %{
      id: "ceramic-mug",
      slug: "ceramic-mug",
      name: "Ceramic Mug",
      category: "Home",
      description:
        "A quieter morning, one cup at a time. Hand-finished stoneware with a generous handle and a softly speckled glaze. Holds 300 ml.",
      price_cents: 2_400,
      image: "/assets/products/ceramic-mug.svg",
      badge: "Small batch",
      material: "Glazed stoneware; dishwasher safe",
      variants: [
        %{
          id: "ceramic-mug-chalk",
          label: "Chalk / One size",
          color: "#e9e2d6",
          size: "One size",
          stock: 8
        },
        %{
          id: "ceramic-mug-terracotta",
          label: "Terracotta / One size",
          color: "#b57157",
          size: "One size",
          stock: 5
        }
      ]
    },
    %{
      id: "linen-throw",
      slug: "linen-throw",
      name: "Linen Throw",
      category: "Home",
      description:
        "An inviting extra layer for slow evenings. Airy woven linen, washed for a lived-in softness and finished with a simple fringe. Measures 130 × 180 cm.",
      price_cents: 7_900,
      image: "/assets/products/linen-throw.svg",
      badge: nil,
      material: "100% European linen",
      variants: [
        %{
          id: "linen-throw-oat",
          label: "Oat / One size",
          color: "#cbbd9e",
          size: "One size",
          stock: 5
        },
        %{
          id: "linen-throw-charcoal",
          label: "Charcoal / One size",
          color: "#535551",
          size: "One size",
          stock: 0
        }
      ]
    },
    %{
      id: "wool-beanie",
      slug: "wool-beanie",
      name: "Wool Beanie",
      category: "Accessories",
      description:
        "Warmth without the weight. A rib-knit beanie with a soft folded brim, made for crisp mornings and the long way home.",
      price_cents: 3_500,
      image: "/assets/products/wool-beanie.svg",
      badge: "New",
      material: "100% responsibly sourced merino wool",
      variants: [
        %{
          id: "wool-beanie-moss",
          label: "Moss / One size",
          color: "#586b4d",
          size: "One size",
          stock: 8
        },
        %{
          id: "wool-beanie-charcoal",
          label: "Charcoal / One size",
          color: "#535551",
          size: "One size",
          stock: 7
        }
      ]
    },
    %{
      id: "brass-keyring",
      slug: "brass-keyring",
      name: "Brass Keyring",
      category: "Accessories",
      description:
        "A small detail worth keeping. A solid brass tag on a split ring, brushed by hand and designed to develop its own patina with use.",
      price_cents: 1_900,
      image: "/assets/products/brass-keyring.svg",
      badge: "Sold out",
      material: "Solid brushed brass",
      variants: [
        %{
          id: "brass-keyring-brass",
          label: "Brass / One size",
          color: "#b49a57",
          size: "One size",
          stock: 0
        }
      ]
    }
  ]

  def all, do: @products
  def get(id), do: Enum.find(@products, &(&1.id == id))
  def by_slug(slug), do: Enum.find(@products, &(&1.slug == slug))
  def categories, do: @categories

  def filter(params) when is_map(params) do
    query = params |> param("q", :q, "") |> text() |> String.trim() |> String.downcase()
    category = params |> param("category", :category, "") |> text()
    sort = param(params, "sort", :sort, "featured")

    @products
    |> Enum.filter(fn product ->
      (category in ["", "all"] or product.category == category) and
        matches_query?(product, query)
    end)
    |> sort_products(sort)
  end

  def filter(_params), do: @products

  defp param(params, string_key, atom_key, default),
    do: Map.get(params, string_key, Map.get(params, atom_key, default))

  defp text(value) when is_binary(value), do: value
  defp text(_value), do: ""

  defp matches_query?(_product, ""), do: true

  defp matches_query?(product, query) do
    Enum.any?([product.name, product.category, product.description, product.material], fn value ->
      value |> String.downcase() |> String.contains?(query)
    end)
  end

  defp sort_products(products, "price-asc"),
    do: Enum.sort_by(products, &{&1.price_cents, &1.name})

  defp sort_products(products, "price-desc"),
    do: Enum.sort_by(products, &{-&1.price_cents, &1.name})

  defp sort_products(products, "name"), do: Enum.sort_by(products, & &1.name)
  defp sort_products(products, _sort), do: products
end
