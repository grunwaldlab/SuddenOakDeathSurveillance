library(ggplot2)
library(dplyr)
library(tidyr)

# Read metadata
metadata <- read.delim("data/formatted_metadata.tsv", sep="\t", stringsAsFactors = FALSE)
metadata$year <- as.character(metadata$year)

# Define categories to plot with their display names
categories <- c(
  lineage = "Lineage",
  host_species = "Host", 
  year = "Year",
  Country = "Country"
)

# Prepare data for plotting
plot_data <- bind_rows(lapply(names(categories), function(col) {
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
})) %>%
  mutate(category = factor(category, levels = c("Lineage", "Host", "Year", "Country"))) %>%
  arrange(value == "Unknown", value == "Other") %>%
  mutate(value = factor(value, levels = unique(value)))

# Create custom color palette
category_colors <- c(
  "Lineage" = "#1f77b4",
  "Host" = "#ff7f0e", 
  "Year" = "#2ca02c",
  "Country" = "#d62728"
)

# Create plot
abund_plot <- ggplot(plot_data, aes(x = value, y = n, fill = category)) +
  geom_col() +
  facet_grid(.~category, scales = "free_x", space = "free_x",
             labeller = labeller(category = setNames(names(category_colors), names(category_colors)))) +
  scale_fill_manual(values = category_colors) +
  labs(x = NULL, y = "Number of genomes") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 60, hjust = 1),
        legend.position = "none",
        panel.grid.major.x = element_blank(),
        strip.text = element_text(face = "bold")) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05))) +
  # Handle special cases for Unknown/Other
  geom_col(data = subset(plot_data, value %in% c("Unknown", "Other")), 
           aes(fill = value)) +
  scale_fill_manual(values = c(category_colors, 
                               "Unknown" = "#444444", 
                               "Other" = "#666666"),
                    guide = "none")
abund_plot
ggsave(abund_plot, path = 'results', filename = 'genome_abundance_plot.pdf', height = 3, width = 9)
ggsave(abund_plot, path = 'results', filename = 'genome_abundance_plot.png', height = 3, width = 9)
