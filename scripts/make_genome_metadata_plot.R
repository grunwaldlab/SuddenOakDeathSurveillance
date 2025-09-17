library(ggplot2)
library(dplyr)
library(tidyr)
library(viridis)

# Read metadata
metadata <- read.delim("data/formatted_metadata.tsv", sep="\t", stringsAsFactors = FALSE)
metadata$year <- as.character(metadata$year)

# Remove reference sequence
metadata <- metadata[metadata$notes != "Reference", , drop = FALSE]

# Define categories to plot with their display names
categories <- c(
  host_genus = "Host", 
  year = "Year",
  Country = "Country",
  source = "Source"
)

# Reduce number of elements in some categories
condense_rare <- function(values, max_count) {
  counts <- table(values)
  if (length(counts) > max_count) {
    common <- names(sort(counts, decreasing = TRUE))[seq_len(max_count - 1)]
    values[! values %in% common] <- 'Other'
  }
  values
}
metadata$host_genus <- condense_rare(metadata$host_genus, max_count = 15)
metadata$lineage <- condense_rare(metadata$lineage, max_count = 7)


# Prepare data for plotting
lineage_order <- names(sort(table(metadata$lineage), decreasing = F))
lineage_order <- c(lineage_order[lineage_order == 'Other'], lineage_order[lineage_order != 'Other'])
ordered_data <- bind_rows(lapply(names(categories), function(col) {
  out <- metadata %>%
    count(value = !!sym(col)) %>%
    mutate(category = categories[col]) %>%
    select(category, value, n)
  if (col == 'year') {
    out <- arrange(out, as.numeric(value))
  } else {
    out <- arrange(out, desc(n))
  }
  return(out)
}))
value_order <- unique(ordered_data$value)

plot_data <- bind_rows(lapply(names(categories), function(col) {
  out <- metadata %>%
    count(value = !!sym(col), lineage) %>%
    mutate(category = categories[col]) %>%
    select(category, value, n, lineage)
  if (col == 'year') {
    out <- arrange(out, as.numeric(value))
  } else {
    out <- arrange(out, desc(n))
  }
  return(out)
})) %>%
  mutate(category = factor(category, levels = c("Lineage", "Host", "Year", "Country", "Source"), ordered = TRUE)) %>%
  mutate(lineage = factor(lineage, levels = lineage_order, ordered = TRUE)) %>%
  arrange(value == "Unknown", value == "Other") %>%
  mutate(value = factor(value, levels = value_order))

# Create custom lineage color palette
lineage_colors[names(lineage_colors) != 'Unknown'] <- viridis(length(lineage_colors) - 1)

# Create plot
abund_plot <- ggplot(plot_data, aes(x = value, y = n, fill = lineage)) +
  geom_col() +
  facet_grid(.~category, scales = "free_x", space = "free_x") +
  scale_fill_viridis(discrete = TRUE, direction = -1) +
  labs(x = NULL, y = "Number of genomes", fill = "Lineage") +
  guides(fill = guide_legend(reverse = TRUE)) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 70, hjust = 1),
        panel.grid.major.x = element_blank(),
        strip.text = element_text(face = "bold")) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05)))
abund_plot
ggsave(abund_plot, path = 'figures', filename = 'genome_abundance_plot.pdf', height = 3, width = 9)
ggsave(abund_plot, path = 'figures', filename = 'genome_abundance_plot.png', height = 3, width = 9, bg = 'white')
