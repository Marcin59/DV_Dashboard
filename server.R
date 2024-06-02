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
    original_stores <- read.csv("./data/Stores.csv")
    original_stores$Country <- gsub("United States", "United States of America", original_stores$Country)
    
    sales <- sales %>%
      left_join(original_stores, by = c("StoreKey")) %>%
      left_join(exchange_rates, by = c("Currency.Code" = "Currency", "Order.Date" = "Date")) %>%
      mutate(Order.Date = as.Date(Order.Date, format = "%m/%d/%Y")) %>%
      mutate(USDQuantity = Quantity / Exchange)
    
    stores <- original_stores %>%
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
        group_by(Country, Order.Date) %>%
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
    
    # UNUSED CURRENCY CONVERSION
    # currencies = c(unique(exchange_rates$Currency))
    # currencies_without_USD = currencies[currencies != "USD"]
    # updateSelectInput(session, "currencyInput", 
    #                   choices =  currencies_without_USD)
    #                   
    # 
    # updateDateInput(session, "dateRateInput",
    #                   min = min(as.Date(exchange_rates$Date, format = "%m/%d/%Y")),
    #                   max = max(as.Date(exchange_rates$Date, format = "%m/%d/%Y")),
    #                   value = max(as.Date(exchange_rates$Date, format = "%m/%d/%Y"))
    # )
    
    selected_currency <- reactiveVal("EUR")
    
    update_buttons <- function(selected_button) {
      buttons <- c("btn_gbp", "btn_eur", "btn_cad", "btn_aud")
      for (button_id in buttons) {
        if (button_id == selected_button) {
          class <- "btn-primary"
        } else {
          class <- "btn-default"
        }
        session$sendCustomMessage(type = "update_button", message = list(id = button_id, class = class))
      }
    }
    
    # Observe button clicks and update selected_currency
    observeEvent(input$btn_gbp, {
      selected_currency("GBP")
      update_buttons("btn_gbp")
    })
    
    observeEvent(input$btn_eur, {
      selected_currency("EUR")
      update_buttons("btn_eur")
    })
    
    observeEvent(input$btn_cad, {
      selected_currency("CAD")
      update_buttons("btn_cad")
    })
    
    observeEvent(input$btn_aud, {
      selected_currency("AUD")
      update_buttons("btn_aud")
    })
    
    # UNUSED CURRENCY CONVERSION
    # output$currencyAmountOutput <- renderText({
    #   currencyAmount <- input$amountInput
    #   rateDate <- input$dateRateInput
    #   rateDate <- format(rateDate, format = "%m/%d/%Y")
    #   rateDate <- sub("/0", "/", rateDate) # remove leading 0 from day
    #   rateDate <- sub("^0", "", rateDate) # remove leading 0 from month
    #   
    #   rate <- exchange_rates %>%
    #     filter(Currency == selected_currency(), Date == rateDate) %>%
    #     select(Exchange)
    #   
    #   return(paste("Amount in USD: ", round(currencyAmount / rate$Exchange, 2)))
    # })
    
    output$currencyRatePlot <- renderPlot({
      currencyType <- selected_currency()
      rate <- exchange_rates %>%
        filter(Currency == currencyType) %>%
        mutate(Exchange = 1 / Exchange) %>%
        mutate(Date = as.Date(Date, format = "%m/%d/%Y"))
      
      last_value <- tail(rate$Exchange, 1)
      
      rate <- rate %>%
        mutate(NextExchange = lead(Exchange),
               NextDate = lead(Date),
               Category = ifelse(Exchange >= last_value & NextExchange >= last_value, "Above",
                                 ifelse(Exchange < last_value & NextExchange < last_value, "Below", "Transition")))
      
      ggplot() +
        geom_segment(data = rate %>% filter(Category == "Above"),
                     aes(x = Date, y = Exchange, xend = NextDate, yend = NextExchange),
                     color = "green") +
        geom_segment(data = rate %>% filter(Category == "Below"),
                     aes(x = Date, y = Exchange, xend = NextDate, yend = NextExchange),
                     color = "red") +
        geom_segment(data = rate %>% filter(Category == "Transition"),
                     aes(x = Date, y = Exchange, xend = NextDate, yend = NextExchange),
                     color = "grey") +
        geom_hline(yintercept = last_value, linetype = "dashed") +
        labs(title = paste("Exchange rate for:", currencyType),
             x = "Date",
             y = "Exchange rate (USD)") +
        theme_minimal() +
        theme(text = element_text(size = 18))
    })
    
    output$map <- renderLeaflet({
      leaflet(rv$stores) %>%
        addTiles() %>%
        setView(lng = 0, lat = 50, zoom = 12/5) %>%
        addPolygons(
          data = st_as_sf(rv$stores),
          fillColor = ~country_colors_factor(Country),
          weight = 1,
          opacity = 0.7,
          color = "white",
          dashArray = "3",
          fillOpacity = ~ifelse(Country %in% stores[stores$clicked == 1,]$Country, 0.8, 0.2),
          layerId = ~Country,
          highlightOptions = highlightOptions(
            weight = 2,
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
    
    observeEvent(input$map_shape_click, {
      clicked_point <- input$map_shape_click
      rv$stores[rv$stores$Country == clicked_point$id,]$clicked <- (rv$stores[rv$stores$Country == clicked_point$id,]$clicked + 1) %% 2
      clicked_store = rv$stores[rv$stores$Country == clicked_point$id,]
      rv$income <- sales %>%
        filter(Country %in% rv$stores[rv$stores$clicked == 1,]$Country) %>%
        group_by(Country, Order.Date) %>%
        summarise(income = sum(USDQuantity))
      
      # Create a color palette for the selected countries
      selected_countries <- rv$stores[rv$stores$clicked == 1,]$Country
      color_pal <- colorFactor(topo.colors(length(selected_countries)), domain = selected_countries)
      
      leafletProxy("map") %>% 
        clearShapes() %>%  # Clear all shapes to redraw with new colors
        addPolygons(
          data = st_as_sf(rv$stores),
          fillColor = ~country_colors_factor(Country),
          weight = 1,
          opacity = 1,
          color = "white",
          dashArray = "3",
          fillOpacity = ~ifelse(Country %in% rv$stores[rv$stores$clicked == 1,]$Country, 0.8, 0.2),
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
    
    country_palette <- c("#1f77b4", "#ff7f0e", "#2ca02c", "#d62728", "#9467bd", "#8c564b", "#e377c2", "#bcbd22")
    countries = c("Australia", "United States of America", "Italy", "France", "United Kingdom", "Canada", "Netherlands", "Germany")
    country_colors_factor = colorFactor(country_palette, countries)
    
    # Define a named vector to map countries to colors
    country_colors <- c("Australia" = country_palette[1],
                        "United States of America" = country_palette[8],
                        "Italy" = country_palette[5],
                        "France" = country_palette[3],
                        "United Kingdom" = country_palette[7],
                        "Canada" = country_palette[2],
                        "Netherlands" = country_palette[6],
                        "Germany" = country_palette[4])
    
    output$incomePlot <- renderPlot({
      df <- rv$income %>%
        group_by(Country) %>%
        arrange(Order.Date) %>%
        mutate(cumulative_income = cumsum(income))  # Calculate cumulative sum within each group
      
      ggplot(df, aes(x = Order.Date, y = cumulative_income, fill = Country)) +
        geom_area() +
        labs(title = "Income Over Time by Country",
             x = "Order Date",
             y = "Cumulative Income") +
        theme_minimal() +
        scale_y_continuous(labels = scales::comma) +
        scale_fill_manual(values = country_colors, name = "Country") +
        theme(
          legend.position = c(0.02, 0.98),  # Adjust legend position
          legend.justification = c(0, 1),    # Justify to top-left
          legend.box.just = "left"           # Align legend to left
        )
    })
    output$top_products <- renderPlot({
      top3 <- sales %>%
        filter(Country %in% rv$stores[rv$stores$clicked == 1,]$Country) %>%
        group_by(ProductKey) %>%
        summarise(TotalSales = sum(Quantity)) %>%
        top_n(3, TotalSales) %>%
        head(3)
      
      plot_data <- sales %>%
        filter(Country %in% rv$stores[rv$stores$clicked == 1,]$Country) %>%
        filter(ProductKey %in% top3$ProductKey) %>%
        left_join(products, by = "ProductKey") %>%
        group_by(ProductKey, Country, Product.Name) %>%
        summarise(TotalQuantity = sum(Quantity)) %>%
        ungroup()
      
      df_max <- plot_data %>%
        group_by(Product.Name) %>%
        summarise(max = sum(TotalQuantity))
      
      plot_data <- plot_data %>%
        left_join(df_max, by = "Product.Name")
      
      ggplot(plot_data, aes(y = reorder(Product.Name, max), x = TotalQuantity)) +
        geom_col(aes(fill = Country)) +
        scale_fill_manual(values = country_colors) +  # Use the named vector for colors
        geom_text(data = df_max, aes(label = Product.Name, x = max), hjust = 1.1, vjust = 0.5, color = "black") +
        labs(x = "Total Sales", y = "Product") +
        theme(axis.text.y = element_blank(),          # Remove y-axis labels
              legend.position = "none")               # Remove legend     
    })
    
    
    output$bottom_products <- renderPlot({
      bot3 <- sales %>%
        filter(Country %in% rv$stores[rv$stores$clicked == 1,]$Country) %>%
        group_by(ProductKey) %>%
        summarise(TotalSales = sum(Quantity)) %>%
        top_n(-3, TotalSales) %>%
        tail(3)
      
      plot_data <- sales %>%
        filter(Country %in% rv$stores[rv$stores$clicked == 1,]$Country) %>%
        filter(ProductKey %in% bot3$ProductKey) %>%
        left_join(products, by = "ProductKey") %>%
        group_by(ProductKey, Country, Product.Name) %>%
        summarise(TotalQuantity = sum(Quantity)) %>%
        ungroup()
      
      df_max <- plot_data %>%
        group_by(Product.Name) %>%
        summarise(max = sum(TotalQuantity))
      
      plot_data <- plot_data %>%
        left_join(df_max, by = "Product.Name")
      
      ggplot(plot_data, aes(y = reorder(Product.Name, max), x = TotalQuantity)) +
        geom_col(aes(fill = Country)) +
        scale_fill_manual(values = country_colors) +  # Use the named vector for colors
        geom_text(data = df_max, aes(label = Product.Name, x = max), hjust = 1.1, vjust = 0.5, color = "black") +
        labs(x = "Total Sales", y = "Product") +
        theme(axis.text.y = element_blank(),          # Remove y-axis labels
              legend.position = "none")               # Remove legend  
    })
    
    output$top_stores <- renderPlot({
      sales %>%
        filter(Country %in% rv$stores[rv$stores$clicked == 1,]$Country) %>%
        group_by(StoreKey) %>%
        summarise(TotalSales = sum(USDQuantity)) %>%  # Use sum(Quantity) to get the total sales
        top_n(3, TotalSales) %>%
        head(3) %>%
        left_join(original_stores, by = "StoreKey") %>%
        ggplot(aes(x = reorder(State, TotalSales), y = TotalSales)) +
        coord_flip() +
        geom_bar(stat = "identity", color = "#3c8dbc", fill = "#3c8dbc") +
        geom_text(aes(label = State), hjust = 1.1, vjust = 0.5, color = "white") +  # Center the labels
        labs(x = "Store", y = "Total Income($)") +
        theme(axis.text.y = element_blank(),           # Remove x-axis labels
              legend.position = "none")                # Remove legend
    })
    
    output$bottom_stores <- renderPlot({
      sales %>%
        filter(Country %in% rv$stores[rv$stores$clicked == 1,]$Country) %>%
        group_by(StoreKey) %>%
        summarise(TotalSales = sum(USDQuantity)) %>%  # Use sum(Quantity) to get the total sales
        top_n(-3, TotalSales) %>%
        tail(3) %>%
        left_join(original_stores, by = "StoreKey") %>%
        ggplot(aes(x = reorder(State, TotalSales), y = TotalSales)) +
        coord_flip() +
        geom_bar(stat = "identity", color = "#3c8dbc", fill = "#3c8dbc") +
        geom_text(aes(label = State), hjust = 1.1, vjust = 0.5, color = "white") +  # Center the labels
        labs(x = "Store", y = "Total Income($)") +
        theme(axis.text.y = element_blank(),           # Remove x-axis labels
              legend.position = "none")                # Remove legend
    })
}
