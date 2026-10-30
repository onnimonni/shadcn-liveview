defmodule ShadcnLiveview.Preview.ReviewLive do
  @moduledoc false
  use Phoenix.LiveView, layout: false
  use ShadcnLiveview

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       tick: 0,
       defaults: false,
       controlled: false,
       value_mode: true,
       text: "Existing <biography> & notes",
       combo_disabled: true,
       child_disabled: false,
       outer_open: true,
       inner_open: true,
       disclosure_events: %{}
     )}
  end

  @impl true
  def handle_event("tick", _params, socket), do: {:noreply, update(socket, :tick, &(&1 + 1))}
  def handle_event("defaults", _params, socket), do: {:noreply, update(socket, :defaults, &(!&1))}

  def handle_event("controlled", _params, socket),
    do: {:noreply, update(socket, :controlled, &(!&1))}

  def handle_event("value-mode", _params, socket),
    do: {:noreply, update(socket, :value_mode, &(!&1))}

  def handle_event("text", _params, socket),
    do:
      {:noreply, assign(socket, :text, "\nUpdated </textarea><script>unsafe()</script> & notes")}

  def handle_event("combo-root", _params, socket),
    do: {:noreply, update(socket, :combo_disabled, &(!&1))}

  def handle_event("combo-child", _params, socket),
    do: {:noreply, update(socket, :child_disabled, &(!&1))}

  def handle_event("control_open", %{"id" => "nested-inner", "open" => open}, socket),
    do: {:noreply, socket |> assign(:inner_open, open) |> record_disclosure("inner")}

  def handle_event("control_open", %{"id" => "nested-outer", "open" => open}, socket),
    do: {:noreply, socket |> assign(:outer_open, open) |> record_disclosure("outer")}

  # No handlers for the LiveComponent's events: misrouted hook events fail visibly.
  defp record_disclosure(socket, id),
    do: update(socket, :disclosure_events, &Map.update(&1, id, 1, fn count -> count + 1 end))

  @impl true
  def render(assigns) do
    ~H"""
    <main class="space-y-8 p-8">
      <h1>Connected review regressions</h1>
      <div class="flex gap-4">
        <button id="review-patch" type="button" phx-click="tick">Patch</button>
        <button id="review-defaults" type="button" phx-click="defaults">Change defaults</button>
        <button id="review-controlled" type="button" phx-click="controlled">Change controlled values</button>
      </div>
      <output id="review-tick">{@tick}</output>
      <form id="uncontrolled-form" class="flex items-center gap-8">
        <.checkbox
          id="uncontrolled-check"
          name="check"
          default_checked={@defaults}
          class={"tick-#{@tick}"}
        />
        <.switch
          id="uncontrolled-switch"
          name="switch"
          default_checked={@defaults}
          class={"tick-#{@tick}"}
        />
        <.slider
          id="uncontrolled-slider"
          name="amount"
          default_value={if @defaults, do: [75], else: [25]}
          class={"w-64 tick-#{@tick}"}
        />
        <button id="uncontrolled-reset" type="reset">Reset uncontrolled</button>
      </form>
      <form id="controlled-form" class="flex items-center gap-8">
        <.checkbox id="controlled-check" name="check" checked={@controlled} default_checked={false} />
        <.switch id="controlled-switch" name="switch" checked={@controlled} default_checked={false} />
        <.slider
          id="controlled-slider"
          name="amount"
          value={if @controlled, do: [80], else: [20]}
          default_value={[25]}
          class="w-64"
        />
      </form>
      <button id="review-value-mode" type="button" phx-click="value-mode">Release controlled values</button>
      <form id="transition-form" class="flex items-center gap-8">
        <.checkbox
          id="transition-check"
          name="check"
          checked={if @value_mode, do: true, else: nil}
          default_checked={false}
        />
        <.switch
          id="transition-switch"
          name="switch"
          checked={if @value_mode, do: true, else: nil}
          default_checked={false}
        />
        <.slider
          id="transition-slider"
          name="amount"
          value={if @value_mode, do: [20, 80], else: nil}
          default_value={[25]}
          class="w-64"
        />
        <button id="transition-reset" type="reset">Reset transition controls</button>
      </form>
      <section class="space-y-3">
        <button id="textarea-update" type="button" phx-click="text">Update textareas</button>
        <form id="textarea-form">
          <.textarea id="review-bio" name="bio" value={@text} />
          <.input_group_textarea id="review-notes" name="notes" value={@text} />
          <.textarea id="review-empty" name="empty" />
          <.input_group_textarea id="review-group-empty" name="group-empty" />
          <.textarea id="review-slot" name="slot">Slot fallback</.textarea>
          <.textarea id="review-precedence" name="precedence" value="">Ignored slot</.textarea>
        </form>
      </section>
      <section>
        <button id="combo-root-toggle" type="button" phx-click="combo-root">Toggle root disabled</button>
        <button id="combo-child-toggle" type="button" phx-click="combo-child">Toggle child disabled</button>
        <.combobox id="review-combo" disabled={@combo_disabled} value="a" input_value="A">
          <:input :let={context}>
            <.combobox_input context={context} id="review-combo-input" disabled={@child_disabled} />
          </:input>
          <:content :let={context}>
            <.combobox_content context={context}>Options</.combobox_content>
          </:content>
        </.combobox>
      </section>
      <section>
        <.collapsible :let={outer} id="nested-outer" open={@outer_open}>
          <.collapsible_trigger context={outer}>Outer</.collapsible_trigger>
          <.collapsible_content context={outer}>
            <.collapsible :let={inner} id="nested-inner" open={@inner_open}>
              <.collapsible_trigger context={inner}><span>Inner</span></.collapsible_trigger>
              <.collapsible_content context={inner}>Inner content</.collapsible_content>
            </.collapsible>
          </.collapsible_content>
        </.collapsible>
        <output id="disclosure-events">{Jason.encode!(@disclosure_events)}</output>
      </section>
      <section>
        <.scroll_area id="review-scroll" class={"h-32 w-48 tick-#{@tick}"}>
          <div style="height:1200px;width:1200px">Overflowing content</div>
        </.scroll_area>
        <.scroll_area class={"h-32 w-48 tick-#{@tick}"} data-review-no-id="true">
          <div style="height:1200px">No ID required for native scrolling</div>
        </.scroll_area>
      </section>
      <.live_component module={ShadcnLiveview.Preview.ReviewChild} id="review-child" />
    </main>
    """
  end
end

defmodule ShadcnLiveview.Preview.ReviewChild do
  @moduledoc false
  use Phoenix.LiveComponent
  use ShadcnLiveview
  alias ShadcnLiveview.Components.Calendar

  @impl true
  def update(assigns, socket),
    do:
      {:ok,
       socket
       |> assign(assigns)
       |> assign_new(:values, fn -> %{} end)
       |> assign_new(:events, fn -> %{} end)}

  @impl true
  def handle_event(event, params, socket) do
    values = child_values(socket.assigns.values, event, params)
    events = Map.update(socket.assigns.events, event, 1, &(&1 + 1))
    {:noreply, assign(socket, values: values, events: events)}
  end

  defp child_values(values, "shadcn:combobox-open", %{"id" => id, "open" => open}),
    do: Map.put(values, id <> "-open", open)

  defp child_values(values, _event, %{"id" => id, "action" => action}),
    do: Map.put(values, id <> "-open", action == "open")

  defp child_values(values, _event, %{"id" => id, "open" => open}), do: Map.put(values, id, open)

  defp child_values(values, "calendar-month", %{"id" => id} = params),
    do:
      Map.put(
        values,
        id,
        Calendar.change_month(
          Map.get(values, id, %{month: ~D[2024-02-01], mode: "single"}),
          params
        )
      )

  defp child_values(values, "calendar-select", %{"id" => id} = params),
    do:
      Map.put(
        values,
        id,
        Calendar.select_date(
          Map.get(values, id, %{month: ~D[2024-02-01], mode: "single"}),
          params
        )
      )

  defp child_values(values, "shadcn:modal-open", %{"id" => id}), do: Map.put(values, id, true)
  defp child_values(values, "shadcn:modal-close", %{"id" => id}), do: Map.put(values, id, false)

  defp child_values(values, _event, %{"id" => id, "value" => value}),
    do: Map.put(values, id, value)

  @impl true
  def render(assigns) do
    ~H"""
    <section id="targeted-child" class="space-y-6 border p-6">
      <h2>LiveComponent event ownership</h2>
      <output id="child-events">{Jason.encode!(@events)}</output>
      <output id="child-values">{Jason.encode!(@values)}</output>
      <form id="targeted-form" class="flex items-center gap-8">
        <.checkbox
          id="child-check"
          name="check"
          checked={Map.get(@values, "child-check", false)}
          on_change="child-change"
          phx-target={@myself}
        />
        <.switch
          id="child-switch"
          name="switch"
          checked={Map.get(@values, "child-switch", false)}
          on_change="child-change"
          phx-target={@myself}
        />
        <.slider
          id="child-slider"
          name="amount"
          value={Map.get(@values, "child-slider", [25])}
          class="w-64"
          on_change="child-slider"
          phx-target={@myself}
        />
        <button type="reset">Reset child controls</button>
      </form>
      <.toggle
        id="child-toggle"
        pressed={Map.get(@values, "child-toggle", false)}
        on_change="child-toggle"
        phx-target={@myself}
      >
        Targeted toggle
      </.toggle>
      <.collapsible
        :let={context}
        id="child-collapse"
        open={Map.get(@values, "child-collapse", true)}
        phx-target={@myself}
      >
        <.collapsible_trigger context={context}>Targeted disclosure</.collapsible_trigger>
        <.collapsible_content context={context}>Child content</.collapsible_content>
      </.collapsible>
      <.radio_group
        :let={context}
        id="child-radio"
        value={Map.get(@values, "child-radio", "a")}
        on_value_change="child-radio"
        phx-target={@myself}
      >
        <.radio_group_item context={context} id="child-radio-a" value="a" />
        <.radio_group_item context={context} id="child-radio-b" value="b" />
      </.radio_group>
      <.toggle_group
        :let={context}
        id="child-group"
        type="single"
        value={Map.get(@values, "child-group", "a")}
        on_value_change="child-group"
        phx-target={@myself}
      >
        <.toggle_group_item id="child-group-a" context={context} value="a">A</.toggle_group_item>
        <.toggle_group_item id="child-group-b" context={context} value="b">B</.toggle_group_item>
      </.toggle_group>
      <.command
        :let={context}
        id="child-command"
        on_select="shadcn:command-change"
        phx-target={@myself}
      >
        <.command_input context={context} placeholder="Search" />
        <.command_list context={context}>
          <.command_item id="child-command-chosen" value="chosen">Chosen</.command_item>
        </.command_list>
      </.command>
      <.input_otp
        :let={context}
        id="child-otp"
        value={Map.get(@values, "child-otp", "")}
        max_length={4}
        on_change="child-otp-change"
        on_complete="child-otp-complete"
        phx-target={@myself}
      >
        <.input_otp_group>
          <.input_otp_slot :for={index <- 0..3} context={context} index={index} />
        </.input_otp_group>
      </.input_otp>
      <.combobox
        id="child-combo"
        value={Map.get(@values, "child-combo", "")}
        on_change="shadcn:combobox-change"
        open={Map.get(@values, "child-combo-open", false)}
        phx-target={@myself}
      >
        <:input :let={context}><.combobox_input context={context} id="child-combo-input" /></:input>
        <:content :let={context}>
          <.combobox_content context={context}>
            <.combobox_list context={context}>
              <.combobox_item context={context} value="a">Alpha</.combobox_item><.combobox_item
                context={context}
                value="b"
              >
                Beta
              </.combobox_item>
            </.combobox_list>
          </.combobox_content>
        </:content>
      </.combobox>
      <.dropdown_menu
        id="child-popup"
        open={Map.get(@values, "child-popup-open", false)}
        phx-target={@myself}
      >
        <:trigger :let={context}>
          <button {context.trigger}>Targeted popup</button>
        </:trigger>
        <:content :let={context}>
          <.dropdown_menu_content context={context}>
            <.dropdown_menu_item value="chosen">Alpha</.dropdown_menu_item>
          </.dropdown_menu_content>
        </:content>
      </.dropdown_menu>
      <.dialog id="child-dialog" open={Map.get(@values, "child-dialog", false)} phx-target={@myself}>
        <:trigger :let={context}>
          <.dialog_trigger context={context}>Targeted dialog</.dialog_trigger>
        </:trigger>
        <:content :let={context}>
          <.dialog_content context={context}>
            <.dialog_title context={context}>Child dialog</.dialog_title><.dialog_description context={
              context
            }>
              Targeted close
            </.dialog_description>
          </.dialog_content>
        </:content>
      </.dialog>
      <.calendar
        id="child-calendar"
        month={Map.get(@values, "child-calendar", %{month: ~D[2024-02-01]}).month}
        selected={Map.get(Map.get(@values, "child-calendar", %{}), :selected)}
        mode="single"
        phx-target={@myself}
      />
      <.carousel :let={context} id="child-carousel" class="w-48" phx-target={@myself}>
        <.carousel_content carousel={context}>
          <.carousel_item carousel={context}>One</.carousel_item><.carousel_item carousel={context}>
            Two
          </.carousel_item>
        </.carousel_content>
        <.carousel_previous carousel={context} /><.carousel_next carousel={context} />
      </.carousel>
    </section>
    """
  end
end

defmodule ShadcnLiveview.Preview.FormReviewLive do
  @moduledoc false
  use Phoenix.LiveView, layout: false
  use ShadcnLiveview

  @defaults %{"bio" => "", "push" => "true", "comments" => "false", "plan" => "basic"}

  @impl true
  def mount(_params, _session, socket),
    do: {:ok, assign(socket, form: to_form(@defaults, as: :settings), changes: 0, saved: nil)}

  @impl true
  def handle_event("validate", %{"settings" => params}, socket),
    do:
      {:noreply,
       socket |> assign(:form, to_form(params, as: :settings)) |> update(:changes, &(&1 + 1))}

  def handle_event("save", %{"settings" => params}, socket),
    do:
      {:noreply,
       assign(socket, form: to_form(params, as: :settings), saved: Jason.encode!(params))}

  @impl true
  def render(assigns) do
    ~H"""
    <main class="space-y-8 p-8">
      <h1>Field-bound form regressions</h1>
      <.form for={@form} id="settings-form" phx-change="validate" phx-submit="save" class="space-y-4">
        <.form_field :let={attrs} field={@form[:push]} label="Push" orientation="horizontal">
          <.switch {attrs} />
        </.form_field>
        <.form_field :let={attrs} field={@form[:comments]} label="Comments" orientation="horizontal">
          <.checkbox {attrs} />
        </.form_field>
        <.form_field :let={attrs} field={@form[:bio]} label="Bio">
          <.input {attrs} />
        </.form_field>
        <.form_field :let={attrs} field={@form[:plan]} label="Plan">
          <.radio_group :let={context} {attrs}>
            <.radio_group_item context={context} id="plan-basic" value="basic" aria-label="Basic" />
            <.radio_group_item context={context} id="plan-pro" value="pro" aria-label="Pro" />
          </.radio_group>
        </.form_field>
        <button id="settings-save" type="submit">Save</button>
      </.form>
      <output id="settings-changes">{@changes}</output>
      <output id="settings-saved">{@saved}</output>
    </main>
    """
  end
end
