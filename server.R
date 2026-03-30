function(input, output, session) {

  filtered_data <- reactive({
    req(input$sites, input$params, input$date_range)
    data |>
      filter(
        site      %in% input$sites,
        parameter %in% input$params,
        as.Date(DT_round) >= input$date_range[1],
        as.Date(DT_round) <= input$date_range[2]
      )
  })

  plot_ids_rv <- reactiveVal(character(0))

  output$plots <- renderUI({
    df <- filtered_data()
    combos  <- unique(df[, c("site", "parameter")])
    ids     <- paste0("plot_", seq_len(nrow(combos)))
    plot_ids_rv(ids)
    lapply(ids, plotlyOutput, height = "350px")
  })

  observe({
    df <- filtered_data()
    combos <- unique(df[, c("site", "parameter")])

    lapply(seq_len(nrow(combos)), function(i) {
      plot_id <- paste0("plot_", i)
      site_i  <- combos$site[i]
      param_i <- combos$parameter[i]

      output[[plot_id]] <- renderPlotly({
        tr <- df[df$site == site_i & df$parameter == param_i, ]
        tr$flagged <- !is.na(tr$auto_flag) | !is.na(tr$mal_flag)
        tr$flag_text <- paste0(
          ifelse(!is.na(tr$auto_flag), paste0("auto: ", tr$auto_flag), ""),
          ifelse(!is.na(tr$auto_flag) & !is.na(tr$mal_flag), "<br>", ""),
          ifelse(!is.na(tr$mal_flag),  paste0("mal: ",  tr$mal_flag),  "")
        )

        plot_ly(source = "ts") |>
          add_trace(
            data          = tr[!tr$flagged, ],
            x             = ~DT_round, y = ~mean,
            type          = "scatter", mode = "markers",
            name          = "normal",
            marker        = list(color = "steelblue", size = 4),
            hovertemplate = "%{x}<br>%{y}<extra></extra>"
          ) |>
          add_trace(
            data          = tr[tr$flagged, ],
            x             = ~DT_round, y = ~mean,
            text          = ~flag_text,
            type          = "scatter", mode = "markers",
            name          = "flagged",
            marker        = list(color = "red", size = 4),
            hovertemplate = "%{x}<br>%{y}<br>%{text}<extra></extra>"
          ) |>
          layout(
            title     = paste(site_i, "|", param_i),
            xaxis     = list(title = "Date/Time (UTC)"),
            yaxis     = list(title = unique(tr$units)[1]),
            hovermode = "x unified"
          )
      })
    })
  })

  # Sync x-axis across all plots when any one is zoomed/panned
  last_synced_range <- reactiveVal(NULL)

  observeEvent(event_data("plotly_relayout", source = "ts"), {
    ed   <- event_data("plotly_relayout", source = "ts")
    xmin <- ed[["xaxis.range[0]"]]
    xmax <- ed[["xaxis.range[1]"]]

    if (!is.null(xmin) && !is.null(xmax)) {
      new_range <- c(xmin, xmax)
      if (!identical(new_range, last_synced_range())) {
        last_synced_range(new_range)
        lapply(plot_ids_rv(), function(pid) {
          plotlyProxy(pid, session) |>
            plotlyProxyInvoke("relayout", list(
              `xaxis.range[0]` = xmin,
              `xaxis.range[1]` = xmax
            ))
        })
      }
    } else if (isTRUE(ed[["xaxis.autorange"]])) {
      last_synced_range(NULL)
      lapply(plot_ids_rv(), function(pid) {
        plotlyProxy(pid, session) |>
          plotlyProxyInvoke("relayout", list(`xaxis.autorange` = TRUE))
      })
    }
  })
}
