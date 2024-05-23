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
library(dplyr)
library(shinydashboard)
library(sf)
library(geojsonio)

shapefile_path <- "./data/boundaries/ne_10m_admin_0_countries.shp"
countries_boundaries <- st_read(shapefile_path)

# Define server logic required to draw a histogram
function(input, output, session) {
    products <- read.csv("./data/Products.csv")
    
    updateSelectInput(session, "categoryInput", 
                      choices =  c("All", unique(products$Category)))
    updateSelectInput(session, "brandInput", 
                      choices =  c("All", unique(products$Brand)))
    updateSelectInput(session, "colorInput", 
                      choices =  c("All", unique(products$Color)))
    
    
    countries_area <- ne_countries(scale = "medium", returnclass = "sf")
    stores <- read.csv("./data/Stores.csv")
    
    stores <- stores %>%
      group_by(Country) %>%
      summarize(numOfStores = n()) %>%
      left_join(countries_boundaries, by = c("admin" = "Country"))
    
    
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
      p})
    
    output$map <- renderLeaflet({
      leaflet(stores) %>%
        addTiles() %>%
        setView(lng = 0, lat = 0, zoom = 12/5) %>%
        addPolygons(
          fillColor = ~colorQuantile("YlGnBu", numOfStores)(numOfStores),
          weight = 1,
          opacity = 1,
          color = "white",
          dashArray = "3",
          fillOpacity = 0.7,
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
}
