library(ggplot2)
library(dplyr)
library(tidyr)

# Read metadata
metadata <- read.delim("data/formatted_metadata.tsv", sep="\t", stringsAsFactors = FALSE)
metadata$year <- as.character(metadata$year)

# Remove reference sequence
metadata <- metadata[metadata$notes != "Reference", , drop = FALSE]

# Define categories to plot with their display names
categories <- c(
  lineage = "Lineage",
  host_species = "Host", 
  year = "Year",
  Country = "Country",
  source = "Source"
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
  mutate(category = factor(category, levels = c("Lineage", "Host", "Year", "Country", "Source"))) %>%
  arrange(value == "Unknown", value == "Other") %>%
  mutate(value = factor(value, levels = unique(value)))

# Create custom lineage color palette
lineage_colors <- c(
  "NA1" = "#1f77b4",
  "EU1" = "#ff7f0e", 
  "NA2" = "#2ca02c",
  "EU2" = "#d62728",
  "NP1" = "#9467bd",
  "NP2" = "#8c564b",
  "NP3" = "#e377c2",
  "IC1" = "#7f7f7f",
  "IC3" = "#bcbd22",
  "IC5" = "#17becf",
  "Unknown" = "#444444"
)

# Add lineage information to plot data for coloring
plot_data_with_lineage <- plot_data %>%
  left_join(metadata %>% select(strain, lineage), by = c("value" = "strain")) %>%
  mutate(lineage = ifelse(is.na(lineage), 
                         ifelse(category == "Lineage", value, "Unknown"), 
                         lineage))

# For non-strain values, assign lineage based on the category
plot_data_with_lineage <- plot_data %>%
  mutate(lineage = case_when(
    category == "Lineage" ~ value,
    TRUE ~ "Unknown"
  ))

# Create plot
abund_plot <- ggplot(plot_data_with_lineage, aes(x = value, y = n, fill = lineage)) +
  geom_col() +
  facet_grid(.~category, scales = "free_x", space = "free_x") +
  scale_fill_manual(values = lineage_colors, name = "Lineage") +
  labs(x = NULL, y = "Number of genomes") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 60, hjust = 1),
        panel.grid.major.x = element_blank(),
        strip.text = element_text(face = "bold")) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05)))
abund_plot
ggsave(abund_plot, path = 'results', filename = 'genome_abundance_plot.pdf', height = 3, width = 9)
ggsave(abund_plot, path = 'results', filename = 'genome_abundance_plot.png', height = 3, width = 9)
