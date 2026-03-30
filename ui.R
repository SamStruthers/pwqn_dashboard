fluidPage(
  titlePanel("PWQN Water Quality Dashboard"),

  sidebarLayout(
    sidebarPanel(
      selectizeInput(
        "sites",
        label    = "Sites",
        choices  = site_choices,
        selected = site_choices[1],
        multiple = TRUE,
        options  = list(placeholder = "Select site(s)...")
      ),
      selectizeInput(
        "params",
        label    = "Parameters",
        choices  = param_choices,
        selected = param_choices[1],
        multiple = TRUE,
        options  = list(placeholder = "Select parameter(s)...")
      ),
      sliderInput(
        "date_range",
        label = "Date Range",
        min   = dt_min,
        max   = dt_max,
        value = c(dt_min, dt_max),
        timeFormat = "%Y-%m-%d",
        width = "100%"
      )
    ),

    mainPanel(
      uiOutput("plots")
    )
  )
)
