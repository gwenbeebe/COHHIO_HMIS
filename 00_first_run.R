# Install packages for COHHIO_HMIS
if (!require(pacman)) install.packages("pacman")
pacman::p_load(char = c("tidyverse", "lubridate", "readxl", "scales", "janitor"))

#Install packages for Rminor
if (!require(pacman)) install.packages("pacman")
pacman::p_load(char = c("tidyverse", "lubridate", "scales", "shinydashboard", "shiny", "shinyWidgets", "plotly", "zoo", "DT"))

#Install packages for Rminor_elevated
if (!require(pacman)) install.packages("pacman")
pacman::p_load(char = c("tidyverse", "lubridate", "scales", "shinydashboard", "shiny", "shinyWidgets", "plotly", "zoo", "DT", "writexl", "viridis"))
