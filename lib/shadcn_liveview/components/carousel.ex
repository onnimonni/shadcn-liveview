defmodule ShadcnLiveview.Components.Carousel do
  @moduledoc """
  Composable carousel with an explicit caller ID. Bind the root's slot context with
  `:let={carousel}` and pass `carousel={carousel}` to content, items and controls.
  Orientation, loop and start_index configure the native scrolling hook. Controls
  are disabled during SSR, like upstream Embla, and synchronize after mounting.
  Items retain their caller-specified basis classes; scrolling supports pointer,
  touch, keyboard, responsive resizing and independently scoped instances.
  Keyboard focus survives server acknowledgements and disabling an end control;
  the region remains keyboard reachable without changing upstream SSR markup.
  """
  use Phoenix.Component
  import ShadcnLiveview.Helpers

  @control_classes %{
    {"default", "default"} =>
      "group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 bg-primary text-primary-foreground hover:bg-primary/80 h-8 gap-1.5 px-2.5 has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2 absolute touch-manipulation rounded-full",
    {"default", "xs"} =>
      "group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 bg-primary text-primary-foreground hover:bg-primary/80 h-6 gap-1 px-2 text-xs in-data-[slot=button-group]:rounded-lg has-data-[icon=inline-end]:pr-1.5 has-data-[icon=inline-start]:pl-1.5 [&_svg:not([class*='size-'])]:size-3 absolute touch-manipulation rounded-full",
    {"default", "sm"} =>
      "group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 bg-primary text-primary-foreground hover:bg-primary/80 h-7 gap-1 px-2.5 text-[0.8rem] in-data-[slot=button-group]:rounded-lg has-data-[icon=inline-end]:pr-1.5 has-data-[icon=inline-start]:pl-1.5 [&_svg:not([class*='size-'])]:size-3.5 absolute touch-manipulation rounded-full",
    {"default", "lg"} =>
      "group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 bg-primary text-primary-foreground hover:bg-primary/80 h-9 gap-1.5 px-2.5 has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2 absolute touch-manipulation rounded-full",
    {"default", "icon"} =>
      "group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 bg-primary text-primary-foreground hover:bg-primary/80 size-8 absolute touch-manipulation rounded-full",
    {"default", "icon-xs"} =>
      "group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 bg-primary text-primary-foreground hover:bg-primary/80 size-6 in-data-[slot=button-group]:rounded-lg [&_svg:not([class*='size-'])]:size-3 absolute touch-manipulation rounded-full",
    {"default", "icon-sm"} =>
      "group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 bg-primary text-primary-foreground hover:bg-primary/80 size-7 in-data-[slot=button-group]:rounded-lg absolute touch-manipulation rounded-full",
    {"default", "icon-lg"} =>
      "group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 bg-primary text-primary-foreground hover:bg-primary/80 size-9 absolute touch-manipulation rounded-full",
    {"outline", "default"} =>
      "group/button inline-flex shrink-0 items-center justify-center border bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 border-border bg-background hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:border-input dark:bg-input/30 dark:hover:bg-input/50 h-8 gap-1.5 px-2.5 has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2 absolute touch-manipulation rounded-full",
    {"outline", "xs"} =>
      "group/button inline-flex shrink-0 items-center justify-center border bg-clip-padding font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 border-border bg-background hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:border-input dark:bg-input/30 dark:hover:bg-input/50 h-6 gap-1 px-2 text-xs in-data-[slot=button-group]:rounded-lg has-data-[icon=inline-end]:pr-1.5 has-data-[icon=inline-start]:pl-1.5 [&_svg:not([class*='size-'])]:size-3 absolute touch-manipulation rounded-full",
    {"outline", "sm"} =>
      "group/button inline-flex shrink-0 items-center justify-center border bg-clip-padding font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 border-border bg-background hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:border-input dark:bg-input/30 dark:hover:bg-input/50 h-7 gap-1 px-2.5 text-[0.8rem] in-data-[slot=button-group]:rounded-lg has-data-[icon=inline-end]:pr-1.5 has-data-[icon=inline-start]:pl-1.5 [&_svg:not([class*='size-'])]:size-3.5 absolute touch-manipulation rounded-full",
    {"outline", "lg"} =>
      "group/button inline-flex shrink-0 items-center justify-center border bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 border-border bg-background hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:border-input dark:bg-input/30 dark:hover:bg-input/50 h-9 gap-1.5 px-2.5 has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2 absolute touch-manipulation rounded-full",
    {"outline", "icon"} =>
      "group/button inline-flex shrink-0 items-center justify-center border bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 border-border bg-background hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:border-input dark:bg-input/30 dark:hover:bg-input/50 size-8 absolute touch-manipulation rounded-full",
    {"outline", "icon-xs"} =>
      "group/button inline-flex shrink-0 items-center justify-center border bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 border-border bg-background hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:border-input dark:bg-input/30 dark:hover:bg-input/50 size-6 in-data-[slot=button-group]:rounded-lg [&_svg:not([class*='size-'])]:size-3 absolute touch-manipulation rounded-full",
    {"outline", "icon-sm"} =>
      "group/button inline-flex shrink-0 items-center justify-center border bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 border-border bg-background hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:border-input dark:bg-input/30 dark:hover:bg-input/50 size-7 in-data-[slot=button-group]:rounded-lg absolute touch-manipulation rounded-full",
    {"outline", "icon-lg"} =>
      "group/button inline-flex shrink-0 items-center justify-center border bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 border-border bg-background hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:border-input dark:bg-input/30 dark:hover:bg-input/50 size-9 absolute touch-manipulation rounded-full",
    {"secondary", "default"} =>
      "group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 bg-secondary text-secondary-foreground hover:bg-[color-mix(in_oklch,var(--secondary),var(--foreground)_5%)] aria-expanded:bg-secondary aria-expanded:text-secondary-foreground h-8 gap-1.5 px-2.5 has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2 absolute touch-manipulation rounded-full",
    {"secondary", "xs"} =>
      "group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 bg-secondary text-secondary-foreground hover:bg-[color-mix(in_oklch,var(--secondary),var(--foreground)_5%)] aria-expanded:bg-secondary aria-expanded:text-secondary-foreground h-6 gap-1 px-2 text-xs in-data-[slot=button-group]:rounded-lg has-data-[icon=inline-end]:pr-1.5 has-data-[icon=inline-start]:pl-1.5 [&_svg:not([class*='size-'])]:size-3 absolute touch-manipulation rounded-full",
    {"secondary", "sm"} =>
      "group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 bg-secondary text-secondary-foreground hover:bg-[color-mix(in_oklch,var(--secondary),var(--foreground)_5%)] aria-expanded:bg-secondary aria-expanded:text-secondary-foreground h-7 gap-1 px-2.5 text-[0.8rem] in-data-[slot=button-group]:rounded-lg has-data-[icon=inline-end]:pr-1.5 has-data-[icon=inline-start]:pl-1.5 [&_svg:not([class*='size-'])]:size-3.5 absolute touch-manipulation rounded-full",
    {"secondary", "lg"} =>
      "group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 bg-secondary text-secondary-foreground hover:bg-[color-mix(in_oklch,var(--secondary),var(--foreground)_5%)] aria-expanded:bg-secondary aria-expanded:text-secondary-foreground h-9 gap-1.5 px-2.5 has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2 absolute touch-manipulation rounded-full",
    {"secondary", "icon"} =>
      "group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 bg-secondary text-secondary-foreground hover:bg-[color-mix(in_oklch,var(--secondary),var(--foreground)_5%)] aria-expanded:bg-secondary aria-expanded:text-secondary-foreground size-8 absolute touch-manipulation rounded-full",
    {"secondary", "icon-xs"} =>
      "group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 bg-secondary text-secondary-foreground hover:bg-[color-mix(in_oklch,var(--secondary),var(--foreground)_5%)] aria-expanded:bg-secondary aria-expanded:text-secondary-foreground size-6 in-data-[slot=button-group]:rounded-lg [&_svg:not([class*='size-'])]:size-3 absolute touch-manipulation rounded-full",
    {"secondary", "icon-sm"} =>
      "group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 bg-secondary text-secondary-foreground hover:bg-[color-mix(in_oklch,var(--secondary),var(--foreground)_5%)] aria-expanded:bg-secondary aria-expanded:text-secondary-foreground size-7 in-data-[slot=button-group]:rounded-lg absolute touch-manipulation rounded-full",
    {"secondary", "icon-lg"} =>
      "group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 bg-secondary text-secondary-foreground hover:bg-[color-mix(in_oklch,var(--secondary),var(--foreground)_5%)] aria-expanded:bg-secondary aria-expanded:text-secondary-foreground size-9 absolute touch-manipulation rounded-full",
    {"ghost", "default"} =>
      "group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:hover:bg-muted/50 h-8 gap-1.5 px-2.5 has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2 absolute touch-manipulation rounded-full",
    {"ghost", "xs"} =>
      "group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:hover:bg-muted/50 h-6 gap-1 px-2 text-xs in-data-[slot=button-group]:rounded-lg has-data-[icon=inline-end]:pr-1.5 has-data-[icon=inline-start]:pl-1.5 [&_svg:not([class*='size-'])]:size-3 absolute touch-manipulation rounded-full",
    {"ghost", "sm"} =>
      "group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:hover:bg-muted/50 h-7 gap-1 px-2.5 text-[0.8rem] in-data-[slot=button-group]:rounded-lg has-data-[icon=inline-end]:pr-1.5 has-data-[icon=inline-start]:pl-1.5 [&_svg:not([class*='size-'])]:size-3.5 absolute touch-manipulation rounded-full",
    {"ghost", "lg"} =>
      "group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:hover:bg-muted/50 h-9 gap-1.5 px-2.5 has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2 absolute touch-manipulation rounded-full",
    {"ghost", "icon"} =>
      "group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:hover:bg-muted/50 size-8 absolute touch-manipulation rounded-full",
    {"ghost", "icon-xs"} =>
      "group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:hover:bg-muted/50 size-6 in-data-[slot=button-group]:rounded-lg [&_svg:not([class*='size-'])]:size-3 absolute touch-manipulation rounded-full",
    {"ghost", "icon-sm"} =>
      "group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:hover:bg-muted/50 size-7 in-data-[slot=button-group]:rounded-lg absolute touch-manipulation rounded-full",
    {"ghost", "icon-lg"} =>
      "group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 hover:bg-muted hover:text-foreground aria-expanded:bg-muted aria-expanded:text-foreground dark:hover:bg-muted/50 size-9 absolute touch-manipulation rounded-full",
    {"destructive", "default"} =>
      "group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:ring-3 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 bg-destructive/10 text-destructive hover:bg-destructive/20 focus-visible:border-destructive/40 focus-visible:ring-destructive/20 dark:bg-destructive/20 dark:hover:bg-destructive/30 dark:focus-visible:ring-destructive/40 h-8 gap-1.5 px-2.5 has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2 absolute touch-manipulation rounded-full",
    {"destructive", "xs"} =>
      "group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:ring-3 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 bg-destructive/10 text-destructive hover:bg-destructive/20 focus-visible:border-destructive/40 focus-visible:ring-destructive/20 dark:bg-destructive/20 dark:hover:bg-destructive/30 dark:focus-visible:ring-destructive/40 h-6 gap-1 px-2 text-xs in-data-[slot=button-group]:rounded-lg has-data-[icon=inline-end]:pr-1.5 has-data-[icon=inline-start]:pl-1.5 [&_svg:not([class*='size-'])]:size-3 absolute touch-manipulation rounded-full",
    {"destructive", "sm"} =>
      "group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:ring-3 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 bg-destructive/10 text-destructive hover:bg-destructive/20 focus-visible:border-destructive/40 focus-visible:ring-destructive/20 dark:bg-destructive/20 dark:hover:bg-destructive/30 dark:focus-visible:ring-destructive/40 h-7 gap-1 px-2.5 text-[0.8rem] in-data-[slot=button-group]:rounded-lg has-data-[icon=inline-end]:pr-1.5 has-data-[icon=inline-start]:pl-1.5 [&_svg:not([class*='size-'])]:size-3.5 absolute touch-manipulation rounded-full",
    {"destructive", "lg"} =>
      "group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:ring-3 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 bg-destructive/10 text-destructive hover:bg-destructive/20 focus-visible:border-destructive/40 focus-visible:ring-destructive/20 dark:bg-destructive/20 dark:hover:bg-destructive/30 dark:focus-visible:ring-destructive/40 h-9 gap-1.5 px-2.5 has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2 absolute touch-manipulation rounded-full",
    {"destructive", "icon"} =>
      "group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:ring-3 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 bg-destructive/10 text-destructive hover:bg-destructive/20 focus-visible:border-destructive/40 focus-visible:ring-destructive/20 dark:bg-destructive/20 dark:hover:bg-destructive/30 dark:focus-visible:ring-destructive/40 size-8 absolute touch-manipulation rounded-full",
    {"destructive", "icon-xs"} =>
      "group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:ring-3 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 bg-destructive/10 text-destructive hover:bg-destructive/20 focus-visible:border-destructive/40 focus-visible:ring-destructive/20 dark:bg-destructive/20 dark:hover:bg-destructive/30 dark:focus-visible:ring-destructive/40 size-6 in-data-[slot=button-group]:rounded-lg [&_svg:not([class*='size-'])]:size-3 absolute touch-manipulation rounded-full",
    {"destructive", "icon-sm"} =>
      "group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:ring-3 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 bg-destructive/10 text-destructive hover:bg-destructive/20 focus-visible:border-destructive/40 focus-visible:ring-destructive/20 dark:bg-destructive/20 dark:hover:bg-destructive/30 dark:focus-visible:ring-destructive/40 size-7 in-data-[slot=button-group]:rounded-lg absolute touch-manipulation rounded-full",
    {"destructive", "icon-lg"} =>
      "group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:ring-3 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 bg-destructive/10 text-destructive hover:bg-destructive/20 focus-visible:border-destructive/40 focus-visible:ring-destructive/20 dark:bg-destructive/20 dark:hover:bg-destructive/30 dark:focus-visible:ring-destructive/40 size-9 absolute touch-manipulation rounded-full",
    {"link", "default"} =>
      "group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 text-primary underline-offset-4 hover:underline h-8 gap-1.5 px-2.5 has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2 absolute touch-manipulation rounded-full",
    {"link", "xs"} =>
      "group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 text-primary underline-offset-4 hover:underline h-6 gap-1 px-2 text-xs in-data-[slot=button-group]:rounded-lg has-data-[icon=inline-end]:pr-1.5 has-data-[icon=inline-start]:pl-1.5 [&_svg:not([class*='size-'])]:size-3 absolute touch-manipulation rounded-full",
    {"link", "sm"} =>
      "group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 text-primary underline-offset-4 hover:underline h-7 gap-1 px-2.5 text-[0.8rem] in-data-[slot=button-group]:rounded-lg has-data-[icon=inline-end]:pr-1.5 has-data-[icon=inline-start]:pl-1.5 [&_svg:not([class*='size-'])]:size-3.5 absolute touch-manipulation rounded-full",
    {"link", "lg"} =>
      "group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 text-primary underline-offset-4 hover:underline h-9 gap-1.5 px-2.5 has-data-[icon=inline-end]:pr-2 has-data-[icon=inline-start]:pl-2 absolute touch-manipulation rounded-full",
    {"link", "icon"} =>
      "group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 text-primary underline-offset-4 hover:underline size-8 absolute touch-manipulation rounded-full",
    {"link", "icon-xs"} =>
      "group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 text-primary underline-offset-4 hover:underline size-6 in-data-[slot=button-group]:rounded-lg [&_svg:not([class*='size-'])]:size-3 absolute touch-manipulation rounded-full",
    {"link", "icon-sm"} =>
      "group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 text-primary underline-offset-4 hover:underline size-7 in-data-[slot=button-group]:rounded-lg absolute touch-manipulation rounded-full",
    {"link", "icon-lg"} =>
      "group/button inline-flex shrink-0 items-center justify-center border border-transparent bg-clip-padding text-sm font-medium whitespace-nowrap transition-all outline-none select-none focus-visible:border-ring focus-visible:ring-3 focus-visible:ring-ring/50 active:not-aria-[haspopup]:translate-y-px disabled:pointer-events-none disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40 [&_svg]:pointer-events-none [&_svg]:shrink-0 [&_svg:not([class*='size-'])]:size-4 text-primary underline-offset-4 hover:underline size-9 absolute touch-manipulation rounded-full"
  }

  attr :id, :string, required: true
  attr :orientation, :string, default: "horizontal", values: ~w(horizontal vertical)
  attr :loop, :boolean, default: false
  attr :start_index, :integer, default: 0
  attr :class, :string, default: nil

  attr :rest, :global,
    include:
      ~w(id title role tabindex type disabled name value href target rel dir style placeholder autocomplete required readonly form min max step aria-label aria-controls aria-expanded)

  slot :inner_block
  @doc "Renders a layout primitive with explicit slot context and caller-owned state."

  def carousel(assigns) do
    assigns = assign(assigns, :context, %{id: assigns.id, orientation: assigns.orientation})

    ~H"""
    <div
      id={@id}
      data-slot="carousel"
      role="region"
      aria-roledescription="carousel"
      class={classes(["relative", @class])}
      phx-hook=".Carousel"
      phx-value-orientation={@orientation}
      phx-value-loop={to_string(@loop)}
      phx-value-start-index={@start_index}
      {@rest}
    >
      {render_slot(@inner_block, @context)}
    </div>
    <script :type={Phoenix.LiveView.ColocatedHook} name=".Carousel">
      export default {
        mounted() {
          this.abort = new AbortController();
          const on = (target, name, callback, options = {}) => target.addEventListener(name, callback, {...options, signal: this.abort.signal});
          this.index = Number(this.el.getAttribute("phx-value-start-index") || 0); this.serverIndex = this.index;
          on(this.el, "click", event => {
            const button = event.target.closest('[data-slot="carousel-previous"], [data-slot="carousel-next"]');
            if (!button || button.closest('[data-slot="carousel"]') !== this.el) return;
            this.move(button.getAttribute("data-slot") === "carousel-next" ? 1 : -1);
          });
          on(this.el, "keydown", event => {
            if (event.target.closest('input,textarea,select,[contenteditable=true]')) return;
            const vertical = this.vertical();
            const delta = event.key === "ArrowLeft" || (vertical && event.key === "ArrowUp") ? -1 : event.key === "ArrowRight" || (vertical && event.key === "ArrowDown") ? 1 : 0;
            if (delta) { event.preventDefault(); this.move(delta); }
          });
          on(this.el, "pointerdown", event => {
            if (!this.viewport || !this.viewport.contains(event.target) || event.button !== 0 || event.target.closest('button,a,input,textarea,select')) return;
            this.drag = {id: event.pointerId, point: this.vertical() ? event.clientY : event.clientX, offset: this.position()};
            this.viewport.setPointerCapture(event.pointerId);
          });
          on(this.el, "pointermove", event => {
            if (!this.drag || this.drag.id !== event.pointerId) return;
            const distance = this.drag.point - (this.vertical() ? event.clientY : event.clientX);
            if (Math.abs(distance) > 4) { event.preventDefault(); this.scroll(this.drag.offset + distance, "instant"); }
          });
          const end = () => { if (!this.drag) return; const focused = this.el.contains(document.activeElement) ? document.activeElement : null; this.drag = null; this.index = this.nearest(); this.go("smooth"); this.pushEvent("shadcn:carousel-change", {id: this.el.id, value: this.index}, () => this.restoreFocus(focused)); };
          on(this.el, "pointerup", end); on(this.el, "pointercancel", end);
          this.observer = new ResizeObserver(() => { this.measure(); this.go("instant"); });
          this.configure();
        },
        vertical() { return this.el.getAttribute("phx-value-orientation") === "vertical"; },
        position() { return this.vertical() ? this.viewport.scrollTop : this.viewport.scrollLeft; },
        scroll(position, behavior) { this.viewport.scrollTo(this.vertical() ? {top: position, behavior} : {left: position, behavior}); },
        configure() {
          if (!this.el.hasAttribute("tabindex")) this.el.tabIndex = 0;
          this.observer.disconnect();
          this.viewport = [...this.el.querySelectorAll('[data-slot="carousel-content"]')].find(node => node.closest('[data-slot="carousel"]') === this.el);
          if (!this.viewport) return;
          this.track = this.viewport.firstElementChild;
          this.viewport.style.touchAction = this.vertical() ? "pan-x" : "pan-y";
          this.observer.observe(this.viewport); this.observer.observe(this.track);
          this.measure(); this.go("instant");
        },
        measure() {
          if (!this.viewport) return;
          const items = [...this.track.children].filter(node => node.getAttribute("data-slot") === "carousel-item");
          const max = Math.max(0, this.vertical() ? this.viewport.scrollHeight - this.viewport.clientHeight : this.viewport.scrollWidth - this.viewport.clientWidth);
          const origin = items.length ? (this.vertical() ? items[0].offsetTop : items[0].offsetLeft) : 0;
          this.positions = [...new Set(items.map(node => Math.min(max, Math.max(0, (this.vertical() ? node.offsetTop : node.offsetLeft) - origin))))];
          if (!this.positions.length) this.positions = [0];
          this.index = Math.max(0, Math.min(this.index, this.positions.length - 1));
        },
        nearest() { return this.positions.reduce((best, position, index) => Math.abs(position - this.position()) < Math.abs(this.positions[best] - this.position()) ? index : best, 0); },
        move(delta) {
          if (!this.viewport) return;
          const focused = this.el.contains(document.activeElement) ? document.activeElement : null;
          const count = this.positions.length;
          const loop = this.el.getAttribute("phx-value-loop") === "true";
          this.index = loop ? (this.index + delta + count) % count : Math.max(0, Math.min(count - 1, this.index + delta));
          this.go("smooth");
          this.pushEvent("shadcn:carousel-change", {id: this.el.id, value: this.index}, () => this.restoreFocus(focused));
        },
        go(behavior) {
          if (!this.viewport) return;
          this.scroll(this.positions[this.index] || 0, behavior);
          const loop = this.el.getAttribute("phx-value-loop") === "true" && this.positions.length > 1;
          this.el.querySelectorAll('[data-slot="carousel-previous"], [data-slot="carousel-next"]').forEach(button => {
            if (button.closest('[data-slot="carousel"]') !== this.el) return;
            const focused = document.activeElement === button;
            button.disabled = button.getAttribute("phx-value-disabled") === "true" || (!loop && (button.getAttribute("data-slot") === "carousel-previous" ? this.index === 0 : this.index === this.positions.length - 1));
            if (focused && button.disabled) this.el.focus();
          });
          this.el.dispatchEvent(new CustomEvent("carousel:select", {detail: {index: this.index}, bubbles: true}));
        },
        restoreFocus(focused) {
          if (!focused || document.activeElement !== document.body) return;
          const slot = focused.getAttribute("data-slot");
          const replacement = slot && this.el.querySelector('[data-slot="' + slot + '"]');
          const target = focused.isConnected && !focused.disabled ? focused : replacement && !replacement.disabled ? replacement : this.el;
          target.focus();
        },
        updated() { const index = Number(this.el.getAttribute("phx-value-start-index") || 0); if (index !== this.serverIndex) {this.index = index;this.serverIndex = index;} this.configure(); },
        destroyed() { this.abort.abort(); this.observer.disconnect(); }
      }
    </script>
    """
  end

  attr :carousel, :map, required: true
  attr :class, :string, default: nil

  attr :rest, :global,
    include:
      ~w(id title role tabindex type disabled name value href target rel dir style placeholder autocomplete required readonly form min max step aria-label aria-controls aria-expanded)

  slot :inner_block
  @doc "Renders a layout primitive with explicit slot context and caller-owned state."
  def carousel_content(assigns) do
    ~H"""
    <div class="overflow-hidden" data-slot="carousel-content">
      <div
        class={
          classes([
            "flex",
            if(@carousel.orientation == "horizontal", do: "-ml-4", else: "-mt-4 flex-col"),
            @class
          ])
        }
        {@rest}
      >
        {render_slot(@inner_block, @carousel)}
      </div>
    </div>
    """
  end

  attr :carousel, :map, required: true
  attr :class, :string, default: nil

  attr :rest, :global,
    include:
      ~w(id title role tabindex type disabled name value href target rel dir style placeholder autocomplete required readonly form min max step aria-label aria-controls aria-expanded)

  slot :inner_block
  @doc "Renders a layout primitive with explicit slot context and caller-owned state."
  def carousel_item(assigns) do
    basis =
      if Enum.any?(String.split(assigns.class || ""), &String.starts_with?(&1, "basis-")),
        do: nil,
        else: "basis-full"

    assigns = assign(assigns, :basis, basis)

    ~H"""
    <div
      role="group"
      aria-roledescription="slide"
      data-slot="carousel-item"
      class={
        classes([
          "min-w-0 shrink-0 grow-0",
          @basis,
          if(@carousel.orientation == "horizontal", do: "pl-4", else: "pt-4"),
          @class
        ])
      }
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :carousel, :map, required: true

  attr :variant, :string,
    default: "outline",
    values: ~w(default outline secondary ghost destructive link)

  attr :size, :string,
    default: "icon-sm",
    values: ~w(default xs sm lg icon icon-xs icon-sm icon-lg)

  attr :disabled, :boolean, default: nil
  attr :class, :string, default: nil

  attr :rest, :global,
    include:
      ~w(id title role tabindex type disabled name value href target rel dir style placeholder autocomplete required readonly form min max step aria-label aria-controls aria-expanded)

  slot :inner_block
  @doc "Renders a layout primitive with explicit slot context and caller-owned state."
  def carousel_previous(assigns) do
    ~H"""
    <button
      data-slot="carousel-previous"
      data-variant={@variant}
      data-size={@size}
      class={
        classes([
          control_classes(@variant, @size),
          if(@carousel.orientation == "horizontal",
            do: "inset-y-0 -left-12 my-auto",
            else: "-top-12 left-1/2 -translate-x-1/2 rotate-90"
          ),
          @class
        ])
      }
      disabled={if is_nil(@disabled), do: true, else: @disabled}
      phx-value-disabled={to_string(@disabled)}
      {@rest}
    >
      <ShadcnLiveview.Components.Icon.icon name="chevron-left" class="cn-rtl-flip" />
      <span class="sr-only">Previous slide</span>
    </button>
    """
  end

  attr :carousel, :map, required: true

  attr :variant, :string,
    default: "outline",
    values: ~w(default outline secondary ghost destructive link)

  attr :size, :string,
    default: "icon-sm",
    values: ~w(default xs sm lg icon icon-xs icon-sm icon-lg)

  attr :disabled, :boolean, default: nil
  attr :class, :string, default: nil

  attr :rest, :global,
    include:
      ~w(id title role tabindex type disabled name value href target rel dir style placeholder autocomplete required readonly form min max step aria-label aria-controls aria-expanded)

  slot :inner_block
  @doc "Renders a layout primitive with explicit slot context and caller-owned state."
  def carousel_next(assigns) do
    ~H"""
    <button
      data-slot="carousel-next"
      data-variant={@variant}
      data-size={@size}
      class={
        classes([
          control_classes(@variant, @size),
          if(@carousel.orientation == "horizontal",
            do: "inset-y-0 -right-12 my-auto",
            else: "-bottom-12 left-1/2 -translate-x-1/2 rotate-90"
          ),
          @class
        ])
      }
      disabled={if is_nil(@disabled), do: true, else: @disabled}
      phx-value-disabled={to_string(@disabled)}
      {@rest}
    >
      <ShadcnLiveview.Components.Icon.icon name="chevron-right" class="cn-rtl-flip" />
      <span class="sr-only">Next slide</span>
    </button>
    """
  end

  defp control_classes(variant, size), do: Map.fetch!(@control_classes, {variant, size})
end
