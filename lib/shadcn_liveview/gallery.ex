defmodule ShadcnLiveview.Gallery do
  @moduledoc false
  use Phoenix.Component
  use ShadcnLiveview

  def names, do: ["accordion", "alert-dialog", "alert", "aspect-ratio", "attachment", "avatar", "badge", "breadcrumb", "bubble", "button-group", "button", "calendar", "card", "carousel", "chart", "checkbox", "collapsible", "combobox", "command", "context-menu", "dialog", "direction", "drawer", "dropdown-menu", "empty", "field", "hover-card", "input-group", "input-otp", "input", "item", "kbd", "label", "marker", "menubar", "message-scroller", "message", "native-select", "navigation-menu", "pagination", "popover", "progress", "questionnaire", "radio-group", "resizable", "scroll-area", "select", "separator", "sheet", "sidebar", "skeleton", "slider", "sonner", "spinner", "switch", "table", "tabs", "textarea", "toggle-group", "toggle", "tooltip"]

  def render_html(name) do
    case render_fixture(name) do
      nil -> nil
      rendered -> Phoenix.HTML.Safe.to_iodata(rendered) |> IO.iodata_to_binary()
    end
  end

  def dump_all do
    names()
    |> Enum.map(fn name -> {name, render_html(name)} end)
    |> Map.new()
    |> Jason.encode!()
  end

  def render_fixture("accordion") do
    assigns = %{}
    ~H"""
    <.accordion type="single" default_value="item-1">
      <.accordion_item value="item-1">
        <.accordion_trigger>Is it accessible?</.accordion_trigger>
        <.accordion_content>Yes. It adheres to the WAI-ARIA design pattern.</.accordion_content>
      </.accordion_item>
    </.accordion>
    """
  end

  def render_fixture("alert-dialog") do
    assigns = %{}
    ~H"""
    <.alert_dialog open={true}>
      <.alert_dialog_content>
        <.alert_dialog_header>
          <.alert_dialog_title>Are you absolutely sure?</.alert_dialog_title>
          <.alert_dialog_description>
            This action cannot be undone. This will permanently delete your account.
          </.alert_dialog_description>
        </.alert_dialog_header>
        <.alert_dialog_footer>
          <.alert_dialog_cancel>Cancel</.alert_dialog_cancel>
          <.alert_dialog_action>Continue</.alert_dialog_action>
        </.alert_dialog_footer>
      </.alert_dialog_content>
    </.alert_dialog>
    """
  end

  def render_fixture("alert") do
    assigns = %{}
    ~H"""
    <.alert>
      <.alert_title>Heads up!</.alert_title>
      <.alert_description>You can add components to your app using the cli.</.alert_description>
    </.alert>
    """
  end

  def render_fixture("aspect-ratio") do
    assigns = %{}
    ~H"""
    <.aspect_ratio ratio={16 / 9} class="bg-muted flex items-center justify-center">
      <span>16:9 Aspect Ratio</span>
    </.aspect_ratio>
    """
  end

  def render_fixture("attachment") do
    assigns = %{}
    ~H"""
    <.attachment>
      <.attachment_title>document.pdf</.attachment_title>
      <.attachment_description>2.4 MB</.attachment_description>
    </.attachment>
    """
  end

  def render_fixture("avatar") do
    assigns = %{}
    ~H"""
    <.avatar>
      <.avatar_fallback>CN</.avatar_fallback>
    </.avatar>
    """
  end

  def render_fixture("badge") do
    assigns = %{}
    ~H"""
    <.badge variant="secondary">New Feature</.badge>
    """
  end

  def render_fixture("breadcrumb") do
    assigns = %{}
    ~H"""
    <.breadcrumb>
      <.breadcrumb_list>
        <.breadcrumb_item>
          <.breadcrumb_link href="/">Home</.breadcrumb_link>
        </.breadcrumb_item>
        <.breadcrumb_separator />
        <.breadcrumb_item>
          <.breadcrumb_page>Components</.breadcrumb_page>
        </.breadcrumb_item>
      </.breadcrumb_list>
    </.breadcrumb>
    """
  end

  def render_fixture("bubble") do
    assigns = %{}
    ~H"""
    <.bubble>
      <.bubble_content>Hello from bubble chat!</.bubble_content>
    </.bubble>
    """
  end

  def render_fixture("button-group") do
    assigns = %{}
    ~H"""
    <.button_group>
      <.button variant="outline">Left</.button>
      <.button variant="outline">Middle</.button>
      <.button variant="outline">Right</.button>
    </.button_group>
    """
  end

  def render_fixture("button") do
    assigns = %{}
    ~H"""
    <.button variant="default">Click me</.button>
    """
  end

  def render_fixture("calendar") do
    assigns = %{}
    ~H"""
    <.calendar />
    """
  end

  def render_fixture("card") do
    assigns = %{}
    ~H"""
    <.card>
      <.card_header>
        <.card_title>Notifications</.card_title>
        <.card_description>You have 3 unread messages.</.card_description>
      </.card_header>
      <.card_content>
        <p>Everything looks good today.</p>
      </.card_content>
      <.card_footer>
        <.button class="w-full">Mark all as read</.button>
      </.card_footer>
    </.card>
    """
  end

  def render_fixture("carousel") do
    assigns = %{}
    ~H"""
    <.carousel class="w-full max-w-xs">
      <.carousel_content>
        <.carousel_item>
          <div class="p-1">
            <.card>
              <.card_content class="flex aspect-square items-center justify-center p-6">
                <span class="text-4xl font-semibold">1</span>
              </.card_content>
            </.card>
          </div>
        </.carousel_item>
      </.carousel_content>
      <.carousel_previous />
      <.carousel_next />
    </.carousel>
    """
  end

  def render_fixture("chart") do
    assigns = %{}
    ~H"""
    <.chart_container config={%{desktop: %{label: "Desktop", color: "#2563eb"}}} class="min-h-[200px] w-full">
      <div class="p-4 text-center text-muted-foreground">Chart Viewport</div>
    </.chart_container>
    """
  end

  def render_fixture("checkbox") do
    assigns = %{}
    ~H"""
    <div class="flex items-center space-x-2">
      <.checkbox id="terms" />
      <label for="terms" class="text-sm font-medium leading-none">Accept terms</label>
    </div>
    """
  end

  def render_fixture("collapsible") do
    assigns = %{}
    ~H"""
    <.collapsible open={true}>
      <.collapsible_trigger class="px-4 py-2 text-sm font-medium">Toggle Details</.collapsible_trigger>
      <.collapsible_content class="px-4 py-2 text-sm">
        Here is collapsible content.
      </.collapsible_content>
    </.collapsible>
    """
  end

  def render_fixture("combobox") do
    assigns = %{}
    ~H"""
    <.combobox>
      <.combobox_input placeholder="Select framework..." />
      <.combobox_content>
        <.combobox_list>
          <.combobox_item value="next">Next.js</.combobox_item>
          <.combobox_item value="phoenix">Phoenix</.combobox_item>
        </.combobox_list>
      </.combobox_content>
    </.combobox>
    """
  end

  def render_fixture("command") do
    assigns = %{}
    ~H"""
    <.command class="rounded-lg border shadow-md">
      <.command_input placeholder="Type a command or search..." />
      <.command_list>
        <.command_empty>No results found.</.command_empty>
        <.command_group heading="Suggestions">
          <.command_item>Calendar</.command_item>
          <.command_item>Search Emoji</.command_item>
        </.command_group>
      </.command_list>
    </.command>
    """
  end

  def render_fixture("context-menu") do
    assigns = %{}
    ~H"""
    <.context_menu>
      <.context_menu_trigger class="flex h-[150px] w-[300px] items-center justify-center rounded-md border border-dashed text-sm">
        Right click here
      </.context_menu_trigger>
      <.context_menu_content>
        <.context_menu_item>Back</.context_menu_item>
        <.context_menu_item>Forward</.context_menu_item>
        <.context_menu_item>Reload</.context_menu_item>
      </.context_menu_content>
    </.context_menu>
    """
  end

  def render_fixture("dialog") do
    assigns = %{}
    ~H"""
    <.dialog open={true}>
      <.dialog_content>
        <.dialog_header>
          <.dialog_title>Edit profile</.dialog_title>
          <.dialog_description>
            Make changes to your profile here. Click save when you are done.
          </.dialog_description>
        </.dialog_header>
        <.dialog_footer>
          <.button type="submit">Save changes</.button>
        </.dialog_footer>
      </.dialog_content>
    </.dialog>
    """
  end

  def render_fixture("direction") do
    assigns = %{}
    ~H"""
    <.direction_provider dir="ltr">
      <div class="p-2 text-sm">Left to right layout</div>
    </.direction_provider>
    """
  end

  def render_fixture("drawer") do
    assigns = %{}
    ~H"""
    <.drawer open={true}>
      <.drawer_content>
        <.drawer_header>
          <.drawer_title>Drawer Title</.drawer_title>
          <.drawer_description>Drawer Description goes here.</.drawer_description>
        </.drawer_header>
      </.drawer_content>
    </.drawer>
    """
  end

  def render_fixture("dropdown-menu") do
    assigns = %{}
    ~H"""
    <.dropdown_menu open={true}>
      <.dropdown_menu_trigger>
        <.button variant="outline">Open Menu</.button>
      </.dropdown_menu_trigger>
      <.dropdown_menu_content>
        <.dropdown_menu_label>My Account</.dropdown_menu_label>
        <.dropdown_menu_separator />
        <.dropdown_menu_item>Profile</.dropdown_menu_item>
        <.dropdown_menu_item>Billing</.dropdown_menu_item>
      </.dropdown_menu_content>
    </.dropdown_menu>
    """
  end

  def render_fixture("empty") do
    assigns = %{}
    ~H"""
    <.empty>
      <.empty_header>
        <.empty_title>No data available</.empty_title>
        <.empty_description>Get started by creating your first project.</.empty_description>
      </.empty_header>
    </.empty>
    """
  end

  def render_fixture("field") do
    assigns = %{}
    ~H"""
    <.field_set>
      <.field_group>
        <.field>
          <.field_label>Email address</.field_label>
          <.input type="email" placeholder="m@example.com" />
          <.field_description>We will never share your email.</.field_description>
        </.field>
      </.field_group>
    </.field_set>
    """
  end

  def render_fixture("hover-card") do
    assigns = %{}
    ~H"""
    <.hover_card open={true}>
      <.hover_card_trigger>
        <.button variant="link">@nextjs</.button>
      </.hover_card_trigger>
      <.hover_card_content class="w-80">
        <p class="text-sm">The React Framework for the Web.</p>
      </.hover_card_content>
    </.hover_card>
    """
  end

  def render_fixture("input-group") do
    assigns = %{}
    ~H"""
    <.input_group>
      <.input_group_addon>https://</.input_group_addon>
      <.input_group_input placeholder="example.com" />
    </.input_group>
    """
  end

  def render_fixture("input-otp") do
    assigns = %{}
    ~H"""
    <.input_otp max_length={4}>
      <.input_otp_group>
        <.input_otp_slot index={0} />
        <.input_otp_slot index={1} />
        <.input_otp_slot index={2} />
        <.input_otp_slot index={3} />
      </.input_otp_group>
    </.input_otp>
    """
  end

  def render_fixture("input") do
    assigns = %{}
    ~H"""
    <.input type="email" placeholder="Email" />
    """
  end

  def render_fixture("item") do
    assigns = %{}
    ~H"""
    <.item>
      <.item_content>
        <.item_title>Basic Item</.item_title>
        <.item_description>Item description text</.item_description>
      </.item_content>
    </.item>
    """
  end

  def render_fixture("kbd") do
    assigns = %{}
    ~H"""
    <.kbd>Ctrl + K</.kbd>
    """
  end

  def render_fixture("label") do
    assigns = %{}
    ~H"""
    <.label for="test-input">Your email address</.label>
    """
  end

  def render_fixture("marker") do
    assigns = %{}
    ~H"""
    <.marker class="size-2 bg-emerald-500 rounded-full" />
    """
  end

  def render_fixture("menubar") do
    assigns = %{}
    ~H"""
    <.menubar>
      <.menubar_menu>
        <.menubar_trigger>File</.menubar_trigger>
        <.menubar_content>
          <.menubar_item>New Tab</.menubar_item>
          <.menubar_item>New Window</.menubar_item>
        </.menubar_content>
      </.menubar_menu>
    </.menubar>
    """
  end

  def render_fixture("message-scroller") do
    assigns = %{}
    ~H"""
    <.message_scroller_provider>
      <.message_scroller class="h-40 border rounded p-4">
        <p>Message stream content</p>
      </.message_scroller>
    </.message_scroller_provider>
    """
  end

  def render_fixture("message") do
    assigns = %{}
    ~H"""
    <.message>
      <.message_content>Hi, how can I help you today?</.message_content>
    </.message>
    """
  end

  def render_fixture("native-select") do
    assigns = %{}
    ~H"""
    <.native_select>
      <.native_select_option value="1">Option 1</.native_select_option>
      <.native_select_option value="2">Option 2</.native_select_option>
    </.native_select>
    """
  end

  def render_fixture("navigation-menu") do
    assigns = %{}
    ~H"""
    <.navigation_menu>
      <.navigation_menu_list>
        <.navigation_menu_item>
          <.navigation_menu_link href="/docs">Documentation</.navigation_menu_link>
        </.navigation_menu_item>
      </.navigation_menu_list>
    </.navigation_menu>
    """
  end

  def render_fixture("pagination") do
    assigns = %{}
    ~H"""
    <.pagination>
      <.pagination_content>
        <.pagination_item>
          <.pagination_previous href="#" />
        </.pagination_item>
        <.pagination_item>
          <.pagination_link href="#" is_active={true}>1</.pagination_link>
        </.pagination_item>
        <.pagination_item>
          <.pagination_next href="#" />
        </.pagination_item>
      </.pagination_content>
    </.pagination>
    """
  end

  def render_fixture("popover") do
    assigns = %{}
    ~H"""
    <.popover open={true}>
      <.popover_trigger>
        <.button variant="outline">Open popover</.button>
      </.popover_trigger>
      <.popover_content class="w-80">
        <p class="text-sm">Dimensions settings.</p>
      </.popover_content>
    </.popover>
    """
  end

  def render_fixture("progress") do
    assigns = %{}
    ~H"""
    <.progress value={60} class="w-[60%]" />
    """
  end

  def render_fixture("questionnaire") do
    assigns = %{}
    ~H"""
    <.questionnaire>
      <.questionnaire_item>How satisfied are you with our service?</.questionnaire_item>
    </.questionnaire>
    """
  end

  def render_fixture("radio-group") do
    assigns = %{}
    ~H"""
    <.radio_group default_value="comfortable">
      <div class="flex items-center space-x-2">
        <.radio_group_item value="default" id="r1" />
        <.label for="r1">Default</.label>
      </div>
      <div class="flex items-center space-x-2">
        <.radio_group_item value="comfortable" id="r2" />
        <.label for="r2">Comfortable</.label>
      </div>
    </.radio_group>
    """
  end

  def render_fixture("resizable") do
    assigns = %{}
    ~H"""
    <.resizable_panel_group direction="horizontal" class="max-w-md rounded-lg border">
      <.resizable_panel default_size={50}>
        <div class="flex h-[100px] items-center justify-center p-6">One</div>
      </.resizable_panel>
      <.resizable_handle />
      <.resizable_panel default_size={50}>
        <div class="flex h-[100px] items-center justify-center p-6">Two</div>
      </.resizable_panel>
    </.resizable_panel_group>
    """
  end

  def render_fixture("scroll-area") do
    assigns = %{}
    ~H"""
    <.scroll_area class="h-32 w-48 rounded-md border p-4">
      Long scrolling text item list inside scroll area.
    </.scroll_area>
    """
  end

  def render_fixture("select") do
    assigns = %{}
    ~H"""
    <.select open={true}>
      <.select_trigger class="w-[180px]">
        <.select_value placeholder="Select a fruit" />
      </.select_trigger>
      <.select_content>
        <.select_item value="apple">Apple</.select_item>
        <.select_item value="banana">Banana</.select_item>
      </.select_content>
    </.select>
    """
  end

  def render_fixture("separator") do
    assigns = %{}
    ~H"""
    <.separator class="my-4" />
    """
  end

  def render_fixture("sheet") do
    assigns = %{}
    ~H"""
    <.sheet open={true}>
      <.sheet_content>
        <.sheet_header>
          <.sheet_title>Edit profile</.sheet_title>
          <.sheet_description>Make changes to your profile here.</.sheet_description>
        </.sheet_header>
      </.sheet_content>
    </.sheet>
    """
  end

  def render_fixture("sidebar") do
    assigns = %{}
    ~H"""
    <.sidebar_provider>
      <.sidebar>
        <.sidebar_header>
          <h4 class="font-semibold text-sm">Application</h4>
        </.sidebar_header>
        <.sidebar_content>
          <div class="p-2 text-sm text-muted-foreground">Nav items</div>
        </.sidebar_content>
      </.sidebar>
    </.sidebar_provider>
    """
  end

  def render_fixture("skeleton") do
    assigns = %{}
    ~H"""
    <.skeleton class="h-4 w-[250px]" />
    """
  end

  def render_fixture("slider") do
    assigns = %{}
    ~H"""
    <.slider default_value={[50]} max={100} step={1} class="w-[60%]" />
    """
  end

  def render_fixture("sonner") do
    assigns = %{}
    ~H"""
    <.toaster />
    """
  end

  def render_fixture("spinner") do
    assigns = %{}
    ~H"""
    <.spinner class="size-6 text-primary" />
    """
  end

  def render_fixture("switch") do
    assigns = %{}
    ~H"""
    <.switch id="airplane-mode" />
    """
  end

  def render_fixture("table") do
    assigns = %{}
    ~H"""
    <.table>
      <.table_header>
        <.table_row>
          <.table_head class="w-[100px]">Invoice</.table_head>
          <.table_head>Status</.table_head>
          <.table_head class="text-right">Amount</.table_head>
        </.table_row>
      </.table_header>
      <.table_body>
        <.table_row>
          <.table_cell class="font-medium">INV001</.table_cell>
          <.table_cell>Paid</.table_cell>
          <.table_cell class="text-right">$250.00</.table_cell>
        </.table_row>
      </.table_body>
    </.table>
    """
  end

  def render_fixture("tabs") do
    assigns = %{}
    ~H"""
    <.tabs default_value="account" class="w-[400px]">
      <.tabs_list>
        <.tabs_trigger value="account">Account</.tabs_trigger>
        <.tabs_trigger value="password">Password</.tabs_trigger>
      </.tabs_list>
      <.tabs_content value="account">Make changes to your account here.</.tabs_content>
      <.tabs_content value="password">Change your password here.</.tabs_content>
    </.tabs>
    """
  end

  def render_fixture("textarea") do
    assigns = %{}
    ~H"""
    <.textarea placeholder="Type your message here." />
    """
  end

  def render_fixture("toggle-group") do
    assigns = %{}
    ~H"""
    <.toggle_group type="multiple">
      <.toggle_group_item value="bold" aria-label="Toggle bold">B</.toggle_group_item>
      <.toggle_group_item value="italic" aria-label="Toggle italic">I</.toggle_group_item>
      <.toggle_group_item value="underline" aria-label="Toggle underline">U</.toggle_group_item>
    </.toggle_group>
    """
  end

  def render_fixture("toggle") do
    assigns = %{}
    ~H"""
    <.toggle aria-label="Toggle italic">B</.toggle>
    """
  end

  def render_fixture("tooltip") do
    assigns = %{}
    ~H"""
    <.tooltip_provider>
      <.tooltip open={true}>
        <.tooltip_trigger>
          <.button variant="outline">Hover</.button>
        </.tooltip_trigger>
        <.tooltip_content>
          <p>Add to library</p>
        </.tooltip_content>
      </.tooltip>
    </.tooltip_provider>
    """
  end

  def render_fixture(_), do: nil
end
