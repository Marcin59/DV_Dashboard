# Install and load necessary packages
install.packages("ggplot2")
install.packages("plotly")
install.packages("maps")
install.packages("dplyr")

library(ggplot2)
library(plotly)
library(maps)
library(dplyr)

# Get world map data
world_data <- map_data("world")

# Create a ggplot object
p <- ggplot(world_data, aes(x = long, y = lat, group = group)) +
  geom_polygon(aes(fill = region), color = "white") +
  theme_minimal() +
  labs(title = "World Map")

# Convert the ggplot object to a plotly object
interactive_map <- ggplotly(p)

# Display the interactive map
interactive_map

