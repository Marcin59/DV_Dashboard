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
  dashboardHeader(title = "Electronics Retailer"),
  dashboardSidebar(sidebarMenu(
    menuItem("Overview", tabName = "overview", icon = icon("dashboard")),
    menuItem("Products", tabName = "products", icon = icon("th")),
    menuItem("Currency Exchange", tabName = "currency_exchange", icon = icon("exchange"))
  )),
  dashboardBody(includeCSS("./styles.css"), fluidPage(
    tags$head(
      tags$script(
        HTML(
          "
        Shiny.addCustomMessageHandler('update_button', function(message) {
          var btn = $('#' + message.id);
          btn.removeClass('btn-primary btn-default');
          btn.addClass(message.class);
        });
        "
        )
      )
    ),
    tabItems(
    tabItem(tabName = "overview", fluidRow(
      box(
        width = 8,
        height = "calc(100vh - 50px)",
        box(
          width = 12,
          leafletOutput("map", height = "calc((100vh - 50px) * 0.64)", )
        ),
        tags$style(type = "text/css", ".col-sm-12 {padding: 0 !important;}"),
        box(
          width = 12,
          plotOutput("incomePlot", height = "calc((100vh - 50px) * 0.34)", )
        )
      ),
      box(
        width = 4,
        height = "calc(100vh - 50px)",
        valueBox(width = 4, h4("#Stores"), textOutput("numOfStores"), ),
        valueBox(width = 4, h4("#Customers"), textOutput("numOfCustomers"), ),
        valueBox(width = 4, h4("#Products"), textOutput("numOfProducts"), ),
        box(
          title = "Top 3 Products by Sales",
          solidHeader = TRUE,
          width = 12,
          plotOutput("top_products", height = "150px",)
        ),
        box(
          title = "Bottom 3 Products by Sales",
          solidHeader = TRUE,
          width = 12,
          plotOutput("bottom_products", height = "150px",)
        ),
        box(
          title = "Top 3 Stores by Income",
          solidHeader = TRUE,
          width = 12,
          plotOutput("top_stores", height = "150px",)
        ),
        box(
          title = "Bottom 3 Stores by Income",
          solidHeader = TRUE,
          width = 12,
          plotOutput("bottom_stores", height = "150px",)
        ),
      )
    )),
    tabItem(
      tabName = "products",
      box(
        width = "100%",
        height = "calc(100vh - 50px)",
        fluidRow(
          width = 12,
          box(width = 4, selectInput("categoryInput", "Category:", choices = ""),),
          box(width = 4, selectInput("brandInput", "Brand:", choices = "")),
          box(width = 4, selectInput("colorInput", "Color:", choices = "")),
        ),
        fluidRow(column(12, dataTableOutput("productsTable")))
      )
    ),
    tabItem(
      tabName = "currency_exchange",
      box(
        width = "100%",
        height = "calc(100vh - 50px)",
        fluidRow(
          width = 12,
          column(width = 3, actionButton("btn_eur", "EUR", class = "btn-primary", style = "width: 100%")),
          column(width = 3, actionButton("btn_gbp", "GBP", class = "btn-default", style = "width: 100%")),
          column(width = 3, actionButton("btn_cad", "CAD", class = "btn-default", style = "width: 100%")),
          column(width = 3, actionButton("btn_aud", "AUD", class = "btn-default", style = "width: 100%"))
        ),
        # UNUSED CURRENCY CONVERSION
        # fluidRow(
        #   width = 12,
        #   box(width = 4, dateInput("dateRateInput", "Date:", value = "2015-01-01")),
        #   box(width = 4, numericInput("amountInput", "Amount:", value = 0)),
        #   box(width = 4, h4("faewa") ,textOutput("currencyAmountOutput")),
        # ),
        box(width=12, plotOutput("currencyRatePlot", height = "calc((100vh - 50px) * 0.9)")),
        # put previous box on the bottom of the page
      )
    )
  )))
)
