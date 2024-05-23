#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(leaflet)
library(shinydashboard)

dashboardPage(
  dashboardHeader(title = "Dashboard"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Overview", tabName = "overview", icon = icon("dashboard")),
      menuItem("Products", tabName = "products", icon = icon("th"))
    )
  ),
  dashboardBody(
    tags$head(
      tags$style(HTML("
      #map {
        height: 100vh !important;
      }
    "))
    ),
    tabItems(
      tabItem(tabName = "overview", fluidRow(
        column(
          3
        ),
        column(
          9, 
          leafletOutput("map", height = "100%")
        )
      )),
      tabItem(tabName = "products",
          tabBox(
            width = 12,
            fluidRow(
              column(4,
                     selectInput("categoryInput",
                                 "Category:",
                                 choices = "")
              ),
              column(4,
                     selectInput("brandInput",
                                 "Brand:",
                                 choices = "")
              ),
              column(4,
                     selectInput("colorInput",
                                 "Color:",
                                 choices = "")
              ),
            ),
            fluidRow(
              column(
                12,
                dataTableOutput("productsTable")
              )
            )          
          )
      )
    )
  )
)
