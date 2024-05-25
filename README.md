## Global Electronics Retailer Dashboard
![workflow](https://github.com/Marcin59/DV_Dashboard/actions/workflows/r.yml/badge.svg)

### [Demo](https://marcinkapiszewski156048.shinyapps.io/Dashboard/)
Hosted on shinyapps.io free version, so can be a little slow.
### Overview
Welcome to the Global Electronics Retailer Dashboard project! 
This repository contains an interactive R Shiny dashboard that provides
visualizations and insights into the sales data of a global electronics retailer.
The data includes detailed information on sales, customers, products, stores, and exchange rates.

## Team Members:
- Marcin Kapiszewski - 156048
- Adam Tomys - 156057
## Repository Structure

```plaintext
├── data/
│   ├── Sales.csv
│   ├── Customers.csv
│   ├── Products.csv
│   ├── Stores.csv
│   └── Exchange_Rates.csv
├── server.R
├── ui.R
├── styles.css
├── README.md
```
## Content

- data/: This directory contains the CSV files used in the dashboard.
- server.R: The server logic of the Shiny application.
- ui.R: The user interface definition of the Shiny application.
- styles.css: Custom CSS styles for the dashboard.
- README.md: This file, providing an overview of the project.

## [Data](https://mavenanalytics.io/data-playground)

The data for this project is organized into five main tables:
1. Sales
2. Customers
3. Products
4. Stores
5. Exchange Rates

## Data Fields
### Sales
- Order Number: Unique ID for each order
- Line Item: Identifies individual products purchased as part of an order
- Order Date: Date the order was placed
- Delivery Date: Date the order was delivered
- CustomerKey: Unique key identifying which customer placed the order
- StoreKey: Unique key identifying which store processed the order
- ProductKey: Unique key identifying which product was purchased
- Quantity: Number of items purchased
- Currency Code: Currency used to process the order

### Customers
- CustomerKey: Primary key to identify customers
- Gender: Customer gender
- Name: Customer full name
- City: Customer city
- State Code: Customer state (abbreviated)
- State: Customer state (full)
- Zip Code: Customer zip code
- Country: Customer country
- Continent: Customer continent
- Birthday: Customer date of birth

### Products
- ProductKey: Primary key to identify products
- Product Name: Product name
- Brand: Product brand
- Color: Product color
- Unit Cost USD: Cost to produce the product in USD
- Unit Price USD: Product list price in USD
- SubcategoryKey: Key to identify product subcategories
- Subcategory: Product subcategory name
- CategoryKey: Key to identify product categories
- Category: Product category name

### Stores
- StoreKey: Primary key to identify stores
- Country: Store country
- State: Store state
- Square Meters: Store footprint in square meters
- Open Date: Store open date

### Exchange Rates
- Date: Date
- Currency: Currency code
- Exchange: Exchange rate compared to USD

## Running the Dashboard
To run the dashboard locally, follow these steps:
1. Clone the repository:
 ```bash
git clone https://github.com/Marcin59/DV_Dashboard.git
cd DV-Dashboard
 ```
2. Install the necessary R packages:
```R
install.packages(c("shiny", "leaflet", "ggplot2", "dplyr", "shinydashboard", "rnaturalearth", "rnaturalearthdata", "sf"))
```
3. Run the Shiny app:
```R
shiny::runApp()
```  
  
