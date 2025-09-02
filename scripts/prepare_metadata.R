# Format input files

# Load libraries
library(sp)
library(sf)
library(tidyverse)
library(ggplot2)
library(viridis)
library(ggmap)
library(geonames)
library(metacoder)

# Set input file paths
metadata_path <- 'data/Pram_MetaData.csv'
sample_fasta_path <- 'data/global_n661_mt.fasta'
reference_fasta_path <- 'data/mtMartin2007_PR-102_v3.1.mt.fasta'

# Set output file paths
modified_metadata_output_path <- 'data/metadata_modified.tsv'
coordinate_output_path <- 'data/lat_longs.tsv'
color_output_path <- 'data/colors.tsv'
dropped_output_path <- 'data/dropped_strains.txt'

# Parse input files
metadata <- read_csv(metadata_path)
reference_sequence <- read_fasta(reference_fasta_path)
sample_sequences <- read_fasta(sample_fasta_path)

# Reformat metadata column names
metadata <- metadata %>%
  rename(strain = isolate_id_orig,
         isolate_id = "Isolate_ID(GL)",
         gps_coord = "GPS Coordinates")
colnames(metadata) <- tolower(colnames(metadata))

# Standardize sp./spp/sp 
metadata$host_species <- ifelse(
  metadata$host_species %in% c('sp', 'sp.', 'spp'),
  'sp.',
  metadata$host_species
)

# make species lowercase
metadata$host_species <- tolower(metadata$host_species)

# Remove invalid genus data
metadata$host_genus <- ifelse(
  metadata$host_genus %in% c('unknown', 'Soil'),
  NA,
  metadata$host_genus
)

# Add "source" column as a hybrid of host and environment
metadata <- metadata %>% 
  mutate(source = paste(ifelse(is.na(host_genus), "", host_genus), ifelse(is.na(host_species), "", host_species)),
         source = trimws(source),
         source = ifelse(source == "", host_environment, source)) 

# Add genus to species name
metadata$host_species <- ifelse(
  is.na(metadata$host_genus) | is.na(metadata$host_species),
  NA, 
  paste(metadata$host_genus, metadata$host_species)
)

# Add reference to the metadata file so that its date can be controlled
metadata <- rbind(rep(NA, ncol(metadata)), metadata)
metadata$strain[1] <- names(reference_sequence)[1]
metadata$year[1] <- 2016
metadata$country[1] <- 'USA'
metadata$state[1] <- 'CA'

# fix date format
metadata$date <- paste0(metadata$year, '-01-01')

# Clean up place names so it is easier to look up coordinates
replace_key <- c(
  "N.Ireland" = "Ireland"
)
metadata$country[metadata$country %in% names(replace_key)] <- replace_key[metadata$country[metadata$country %in% names(replace_key)]]

# Make coordinate file
options(geonamesUsername = "fosterz")
get_coords <- function(name, group, ...) {
  res <- GNsearch(name_equals = name, ...)  
  if ("fcode" %in% colnames(res)) {
    res <- filter(res, name == name, fcode %in% c("AREA", "PCLI", "ADM1"))
  }
  res <- res[1, ]
  out <- tibble(group = group, name = name, lat = res$lat, lon = res$lng)
  return(out)
}

coord_data <- bind_rows(
  map_dfr(unique(metadata$country, na.rm = TRUE), get_coords, group = 'Country'),
  map_dfr(unique(metadata$state), get_coords, group = 'State', country = 'USA', fcode = "ADM1")
) %>%
  filter(!is.na(name))

# Add country names to state variable when a state is not available
metadata$state <- ifelse(is.na(metadata$state), metadata$country, metadata$state)
country_as_state <- coord_data[coord_data$group == 'Country', ]
country_as_state$group <- 'State'
coord_data <- rbind(coord_data, country_as_state)

# Write coordinate format
write_tsv(coord_data, file = coordinate_output_path, col_names = FALSE)

# Make dropped strains file
# These will be filtered out of the analysis:
dropped_ids <- c()

# And all IDs associated with a missing location or time:
dropped_ids <- c(dropped_ids, metadata$strain[is.na(metadata$country)])
dropped_ids <- c(dropped_ids, metadata$strain[is.na(metadata$year) | metadata$year > 2025 | metadata$year < 1600])

# Ignore isolates with no FASTA sequence:
seqs <- c(reference_sequence, sample_sequences)
dropped_ids <- c(dropped_ids, metadata$strain[! metadata$strain %in% names(seqs)])

# And write the file, one ID per line:
write_lines(dropped_ids, file = dropped_output_path)

# Remove dropped strains from metadata file since Nextstrain does not seem to always ignore them
metadata <- metadata[! metadata$strain %in% dropped_ids, , drop = FALSE]

# Capitalize some column names for display purposes
colnames(metadata)[colnames(metadata) == 'state'] <- 'State'
colnames(metadata)[colnames(metadata) == 'country'] <- 'Country'

# save metadata file
write_tsv(metadata, file = modified_metadata_output_path)

# Make color file
color_data <- coord_data %>%
  select(group, name) %>%
  mutate(color = viridis(length(group)))
color_data$color <- substr(color_data$color, start = 1, stop = 7)
write_tsv(color_data, file = color_output_path, col_names = FALSE)