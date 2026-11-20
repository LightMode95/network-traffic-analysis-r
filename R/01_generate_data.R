# ==============================================================
# 01_generate_data.R
# Step 1: Create a synthetic network traffic dataset
# Output: data frame `traffic_data` (1,000 hourly records)
# ==============================================================

# Fix the random seed so the data is reproducible
set.seed(123)

# Number of records to simulate
num_records <- 1000

# Hourly timestamps starting 2024-06-03 00:00:00 (about 41.7 days)
timestamps <- seq.POSIXt(
  from = as.POSIXct("2024-06-03 00:00:00"),
  by = "hour",
  length.out = num_records
)

# Generate n random IPv4 addresses (four octets, each 0-255)
generate_ipv4 <- function(n) {
  paste(
    sample(0:255, n, replace = TRUE),
    sample(0:255, n, replace = TRUE),
    sample(0:255, n, replace = TRUE),
    sample(0:255, n, replace = TRUE),
    sep = "."
  )
}

# Source and destination addresses
source_ips      <- generate_ipv4(num_records)
destination_ips <- generate_ipv4(num_records)

# Bytes transferred per record (100 to 10,000)
bytes_transferred <- sample(100:10000, num_records, replace = TRUE)

# Combine everything into one data frame (one row = one record)
traffic_data <- data.frame(
  timestamp         = timestamps,
  source_ip         = source_ips,
  destination_ip    = destination_ips,
  bytes_transferred = bytes_transferred
)

# Quick sanity check: first 6 rows
head(traffic_data)

# Optional: save the dataset so others can inspect it without running R
# dir.create("data", showWarnings = FALSE)
# write.csv(traffic_data, "data/traffic_data.csv", row.names = FALSE)
