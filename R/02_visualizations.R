# ==============================================================
# 02_visualizations.R
# Step 2: Visualizations for network traffic analysis
#   2.1 Time series         2.2 Top talkers
#   2.3 Destination analysis 2.4 Geographical map
# Requires: traffic_data (created by 01_generate_data.R)
# ==============================================================

# ---- Packages (installed only if missing) ---------------------
for (pkg in c("ggplot2", "leaflet", "scales", "htmlwidgets")) {
  if (!requireNamespace(pkg, quietly = TRUE)) install.packages(pkg)
}
library(ggplot2)
library(leaflet)

# ---- Make sure the data exists --------------------------------
if (!exists("traffic_data")) source("R/01_generate_data.R")

# ---- Output folder for saved plots ----------------------------
dir.create("outputs", showWarnings = FALSE)

# Plot size for Jupyter/IRkernel notebooks only (no effect in RStudio)
options(repr.plot.width = 10, repr.plot.height = 6)

# ==============================================================
# 2.1 Time series: bytes transferred over time
# ==============================================================
p_time <- ggplot(traffic_data, aes(x = timestamp, y = bytes_transferred)) +
  geom_line() +
  labs(title = "Network Traffic Over Time",
       x = "Timestamp",
       y = "Bytes Transferred")
print(p_time)
ggsave("outputs/time_series.png", p_time, width = 10, height = 6)

# ==============================================================
# 2.2 Top talkers: source IPs with the most bytes
# ==============================================================
top_talkers <- aggregate(bytes_transferred ~ source_ip,
                         data = traffic_data, FUN = sum)
top_talkers <- top_talkers[order(top_talkers$bytes_transferred,
                                 decreasing = TRUE), ]
top_talkers <- head(top_talkers, 10)  # top 10 for visualization

p_talkers <- ggplot(top_talkers,
                    aes(x = reorder(source_ip, bytes_transferred),
                        y = bytes_transferred,
                        fill = bytes_transferred)) +
  geom_bar(stat = "identity", color = "black") +
  scale_fill_gradient(low = "lightblue", high = "blue") +
  labs(title = "Top 10 Network Talkers",
       x = "Source IP Address",
       y = "Bytes Transferred") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),
        axis.title.x = element_text(size = 12, face = "bold"),
        axis.title.y = element_text(size = 12, face = "bold"),
        legend.position = "none") +
  geom_text(aes(label = scales::comma(bytes_transferred)),
            vjust = -0.3, size = 3.5)
print(p_talkers)
ggsave("outputs/top_talkers.png", p_talkers, width = 10, height = 6)

# ==============================================================
# 2.3 Destination analysis: most accessed destinations
# ==============================================================
destination_summary <- aggregate(bytes_transferred ~ destination_ip,
                                 data = traffic_data, FUN = sum)
destination_summary <- destination_summary[
  order(destination_summary$bytes_transferred, decreasing = TRUE), ]
top_destinations <- head(destination_summary, 10)

p_dest <- ggplot(top_destinations,
                 aes(x = bytes_transferred,
                     y = reorder(destination_ip, bytes_transferred))) +
  geom_segment(aes(x = 0, xend = bytes_transferred,
                   y = reorder(destination_ip, bytes_transferred),
                   yend = reorder(destination_ip, bytes_transferred)),
               color = "grey") +
  geom_point(aes(color = bytes_transferred), size = 4) +
  scale_color_gradient(low = "lightgreen", high = "darkgreen") +
  # extra room on the right so value labels are not clipped
  scale_x_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(title = "Top 10 Network Destinations",
       x = "Bytes Transferred",
       y = "Destination IP Address") +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5, size = 16, face = "bold"),
        axis.title.x = element_text(size = 12, face = "bold"),
        axis.title.y = element_text(size = 12, face = "bold"),
        axis.text.y = element_text(size = 10),
        legend.position = "none") +
  geom_text(aes(label = scales::comma(bytes_transferred)),
            hjust = -0.1, size = 3.5)
print(p_dest)
ggsave("outputs/top_destinations.png", p_dest, width = 10, height = 6)

# ==============================================================
# 2.4 Geographical visualization (interactive map)
# NOTE: coordinates are random and NOT derived from the IPs.
# ==============================================================
set.seed(123)
num_records <- nrow(traffic_data)
traffic_data$source_latitude        <- runif(n = num_records, min = -90,  max = 90)
traffic_data$source_longitude       <- runif(n = num_records, min = -180, max = 180)
traffic_data$destination_latitude   <- runif(n = num_records, min = -90,  max = 90)
traffic_data$destination_longitude  <- runif(n = num_records, min = -180, max = 180)

traffic_map <- leaflet(data = traffic_data) %>%
  addProviderTiles(providers$CartoDB.Positron) %>%
  addCircleMarkers(~source_longitude, ~source_latitude, radius = 5,
                   color = "blue", fillOpacity = 0.5,
                   label = ~paste("Source:", source_ip)) %>%
  addCircleMarkers(~destination_longitude, ~destination_latitude, radius = 5,
                   color = "red", fillOpacity = 0.5,
                   label = ~paste("Destination:", destination_ip))

# One separate line per record (source -> its own destination).
# Passing c(...) over the whole data frame would join every point
# into a single path, so we add the lines row by row instead.
for (i in sample(num_records, 100)) {
  traffic_map <- addPolylines(
    traffic_map,
    lng = c(traffic_data$source_longitude[i], traffic_data$destination_longitude[i]),
    lat = c(traffic_data$source_latitude[i],  traffic_data$destination_latitude[i]),
    color = "green", weight = 2, opacity = 0.7
  )
}

traffic_map <- traffic_map %>%
  addLegend("bottomright",
            colors = c("blue", "red", "green"),
            labels = c("Source IP", "Destination IP", "Traffic Path"),
            title = "Legend") %>%
  setView(lng = mean(traffic_data$source_longitude),
          lat = mean(traffic_data$source_latitude),
          zoom = 1)

traffic_map  # displays in the RStudio Viewer
htmlwidgets::saveWidget(traffic_map, "outputs/traffic_map.html",
                        selfcontained = TRUE)
