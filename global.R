library(shiny)
library(arrow)
library(dplyr)
library(plotly)

data <- arrow::read_parquet("data/data_backup.parquet") |>
  as.data.frame()

site_choices  <- sort(unique(data$site))
param_choices <- sort(unique(data$parameter))
dt_min        <- as.Date(min(data$DT_round, na.rm = TRUE))
dt_max        <- as.Date(max(data$DT_round, na.rm = TRUE))
