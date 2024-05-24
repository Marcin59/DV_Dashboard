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
    includeCSS("./styles.css"),
    fluidPage(
      tabItems(
        tabItem(tabName = "overview", fluidRow(
          box(
            width = 8, 
            height = "900px",
            tags$style(type = "text/css", "#map {position: relative; height: 650px !important;}"),
            leafletOutput("map"),
            tags$style(type = "text/css", ".col-sm-12 {padding: 0 !important;}"),
            box(
              width = 12,
              height = "250px",
              plotOutput("testPlot", height = "200px")
            )
          ),
          box(
            width = 4,
            height = "900px",
            valueBox(
              width = 12,
              h4("Selected Countries"),
              textOutput("selected_countries"),
            ),
            plotOutput("testPlot", height = "200px")
          )
        )),
        tabItem(tabName = "products",
                tabBox(
                  width = 12,
                  fluidRow(
                    box(width = 4,
                           selectInput("categoryInput",
                                       "Category:",
                                       choices = "")
                    ),
                    box(width = 4,
                           selectInput("brandInput",
                                       "Brand:",
                                       choices = "")
                    ),
                    box(width = 4,
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
)
