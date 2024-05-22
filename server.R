#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(shinydashboard)

# Define server logic required to draw a histogram
function(input, output, session) {
    products <- read.csv("./data/Products.csv")
    
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
      p})
}
