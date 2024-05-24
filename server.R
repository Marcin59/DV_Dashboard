#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(leaflet)
library(ggplot2)
library(dplyr)
library(sf)
library(shinydashboard)
library(rnaturalearth)
library(rnaturalearthdata)

countries_boundaries <- ne_countries(scale = "medium", returnclass = "sf")

# Define server logic required to draw a histogram
function(input, output, session) {
    selected_countries <- reactiveVal(c("United States of America"))
  
    products <- read.csv("./data/Products.csv")
    sales <- read.csv("./data/Sales.csv")
    customers <- read.csv("./data/Customers.csv")
    exchange_rates <- read.csv("./data/Exchange_Rates.csv")
    countries_area <- ne_countries(scale = "medium", returnclass = "sf")
    stores <- read.csv("./data/Stores.csv")
    stores$Country <- gsub("United States", "United States of America", stores$Country)
    
    sales <- sales %>%
      left_join(stores, by = c("StoreKey")) %>%
      left_join(exchange_rates, by = c("Currency.Code" = "Currency", "Order.Date" = "Date")) %>%
      mutate(Order.Date = as.Date(Order.Date, format = "%m/%d/%Y")) %>%
      mutate(USDQuantity = Quantity * Exchange)
    
    stores <- stores %>%
      group_by(Country) %>%
      summarize(numOfStores = n()) %>%
      left_join(countries_boundaries, by = c("Country" = "name"))
    stores["name"] = stores["Country"]
    stores$clicked <- 0
    stores[stores$Country == "United States of America",]$clicked = 1
    
    rv <- reactiveValues(
      stores = stores,
      income = sales %>%
        filter(Country %in% stores[stores$clicked == 1,]$Country) %>%
        group_by(Order.Date) %>%
        summarize(income = sum(USDQuantity))
    )
    
    updateSelectInput(session, "categoryInput", 
                      choices =  c("All", unique(products$Category)))
    updateSelectInput(session, "brandInput", 
                      choices =  c("All", unique(products$Brand)))
    updateSelectInput(session, "colorInput", 
                      choices =  c("All", unique(products$Color)))
    
    output$productsTable <- renderDataTable({
      p <- products
      if (input$categoryInput != "All") {
        p <- p[p$Category == input$categoryInput,]
      }
      if (input$brandInput != "All") {
        p <- p[p$Brand == input$brandInput,]
      }
      if (input$colorInput != "All") {
        p <- p[p$Color == input$colorInput,]
      }
      p},
      options = list(
        pageLength = 10,
        dom = 'ftp',
        autoWidth = TRUE,
        scrollX = TRUE
      ))
    
    output$map <- renderLeaflet({
      leaflet(rv$stores) %>%
        addTiles() %>%
        setView(lng = 0, lat = 50, zoom = 12/5) %>%
        addPolygons(
          data = st_as_sf(rv$stores),
          fillColor = ~clicked,
          weight = 1,
          opacity = 1,
          color = "white",
          dashArray = "3",
          fillOpacity = 0.7,
          layerId = ~Country,
          highlightOptions = highlightOptions(
            weight = 2,
            color = "#666",
            dashArray = "",
            fillOpacity = 0.7,
            bringToFront = TRUE),
          label = ~paste(name, ": ", numOfStores, " stores"),
          labelOptions = labelOptions(
            style = list("font-weight" = "normal", padding = "3px 8px"),
            textsize = "15px",
            direction = "auto")
        )
    })
    observeEvent(input$map_shape_click,{
      clicked_point <- input$map_shape_click
      rv$stores[rv$stores$Country == clicked_point$id,]$clicked <- (rv$stores[rv$stores$Country == clicked_point$id,]$clicked + 1) %% 2
      clicked_store = rv$stores[rv$stores$Country == clicked_point$id,]
      rv$income <- sales %>%
        filter(Country %in% rv$stores[rv$stores$clicked == 1,]$Country) %>%
        group_by(Order.Date) %>%
        mutate(income = sum(USDQuantity))
      leafletProxy("map") %>% 
        removeShape(clicked_point$id) %>%
        addPolygons(
          data = st_as_sf(clicked_store),
          fillColor = ~clicked,
          weight = 1,
          opacity = 1,
          color = "white",
          dashArray = "3",
          fillOpacity = 0.7,
          layerId = ~Country,
          highlightOptions = highlightOptions(
            weight = 2,
            color = "#666",
            dashArray = "",
            fillOpacity = 0.7,
            bringToFront = TRUE),
          label = ~paste(name, ": ", numOfStores, " stores"),
          labelOptions = labelOptions(
            style = list("font-weight" = "normal", padding = "3px 8px"),
            textsize = "15px",
            direction = "auto")
        )
      selected_countries(rv$stores[rv$stores$clicked == 1,]$Country)
    })
    output$selected_countries <- renderText({
      rv$stores[rv$stores$clicked==1,]$Country
    })
    
    output$numOfStores <- renderText({
      (rv$stores[rv$stores$clicked==1,] %>%
        summarise(sum = sum(numOfStores)))$sum
    })
    
    output$numOfCustomers<- renderText({
      (customers[rv$stores$clicked==1,] %>%
         summarise(sum = n()))$sum
    })
    
    output$numOfProducts<- renderText({
      (products %>%
         summarise(sum = n()))$sum
    })
    
    output$testPlot <- renderPlot(
      ggplot(rv$stores[rv$stores$clicked==1,], aes(y = numOfStores, x = Country)) +
        geom_boxplot() +
        labs(title = "Number of Stores by Country",
             x = "Number of Stores",
             y = "Country") +
        theme_minimal()
    )
    output$incomePlot <- renderPlot({
      ggplot(rv$income, aes(x = Order.Date, y = cumsum(income))) +
        geom_line() +
        labs(title = "Income Over Time",
             x = "Order Date",
             y = "Income") +
        theme_minimal()
    })
    output$top_products <- renderPlot({
      sales %>%
        filter(Country %in% rv$stores[rv$stores$clicked == 1,]$Country) %>%
        group_by(ProductKey) %>%
        summarise(TotalSales = n()) %>%
        top_n(10, TotalSales) %>%
        left_join(products, by = "ProductKey") %>%
        ggplot(aes(x = reorder(Product.Name, TotalSales), y = TotalSales)) +
        geom_bar(stat = "identity", fill = "blue") +
        coord_flip() +
        labs(title = "Top 10 Products by Sales", x = "Product", y = "Total Sales")
    })
}
