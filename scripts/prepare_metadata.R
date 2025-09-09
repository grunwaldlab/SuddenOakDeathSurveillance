# Format input files

# Load libraries
library(viridis)
library(geonames)
library(argparser)
library(readr)
library(xml2)
library(purrr)

# Parse command line arguments
parser <- arg_parser("Format input files for phylogenetic analysis with augur tools")
parser <- add_argument(parser, "--metadata", help="Input metadata CSV file", default="data/metadata.csv")
parser <- add_argument(parser, "--samples", help="Input sample FASTA file", default="data/ramorum_mito_genomes.fasta")
parser <- add_argument(parser, "--reference", help="Input reference FASTA file", default="data/martin2007_pr-102_v3.1_mito_ref.fasta")
parser <- add_argument(parser, "--metadata_out", help="Output modified metadata TSV file", default="data/formatted_metadata.tsv")
parser <- add_argument(parser, "--coordinate_out", help="Output coordinate TSV file", default="data/lat_longs.tsv")
parser <- add_argument(parser, "--color_out", help="Output color TSV file", default="data/colors.tsv")
parser <- add_argument(parser, "--dropped_out", help="Output dropped strains file", default="data/dropped_strains.txt")
parser <- add_argument(parser, "--max_colors", help="Maximum number of colors used to display categorical variables", default=10)
args <- parse_args(parser)

# Parse input files
metadata <- read_csv(args$metadata)
parse_fasta_headers <- function(path) {
  lines <- readLines(path)
  headers <- lines[grepl(lines, pattern = '^>')]
  sub(headers, pattern = '^>', replacement = '')
}
ref_header <- parse_fasta_headers(args$reference)
sample_headers <- parse_fasta_headers(args$samples)

# Reformat metadata column names
colnames(metadata)[colnames(metadata) == 'Isolate_ID(GL)'] <- 'isolate_id'
colnames(metadata)[colnames(metadata) == 'GPS Coordinates'] <- 'gps_coord'
colnames(metadata)[colnames(metadata) == 'isolate_id_orig'] <- 'strain'
colnames(metadata) <- tolower(colnames(metadata))

# Check that all sequences have metadata
stopifnot(all(sample_headers %in% metadata$strain))

# Standardize sp./spp/sp 
metadata$host_species <- ifelse(
  metadata$host_species %in% c('sp', 'sp.', 'spp'),
  'sp.',
  metadata$host_species
)

# make species lowercase
metadata$host_species <- tolower(metadata$host_species)

# Add genus to species name
metadata$host_species <- ifelse(
  is.na(metadata$host_genus) | is.na(metadata$host_species),
  NA, 
  paste(metadata$host_genus, metadata$host_species)
)

# Identify source of samples for use in publication
parse_and_standardize_tsv <- function(path) {
  x <- read_tsv(path)
  colnames(x) <- gsub(pattern = ' +', replacement = '_', tolower(colnames(x)))
  x
}
present_ids <- function(table, cols) {
  unlist(lapply(cols, function(col) {
    metadata$strain[metadata$strain %in% table[[col]]]
  }))
}
extract_data <- function(table, id_cols, table_id) {
  map_dfr(id_cols, function(col) {
    is_found <- table[[col]] %in% metadata$strain
    data.frame(
      source = table_id,
      col = col,
      index = which(is_found),
      id = table[[col]][is_found]
    )
  })
}


# Nick: "USDA ARS are likely Takao's group and we'll probably have to track the metadata down from supplementary tables in their 2016 and 2018 papers."
elliott_2018_data_raw <- parse_and_standardize_tsv('data/metadata_references/elliott_2018.tsv')
elliott_2018_data <- extract_data(table = elliott_2018_data_raw, id_cols = c('isolate_numbers', 'other_numbers'), table_id = 'Elliott et al. 2018')
elliott_2018_data$year <- elliott_2018_data_raw$year[elliott_2018_data$index]
elliott_2018_data$country <- 'USA'
elliott_2018_data$state <- gsub(pattern = '^.+, ', replacement = '', elliott_2018_data_raw$county_and_state[elliott_2018_data$index])
elliott_2018_data$county <- gsub(pattern = ',? ?(WA|CA)$', replacement = '', elliott_2018_data_raw$county_and_state[elliott_2018_data$index])
elliott_2018_data$lineage <- 'NA1'
elliott_2018_data$host_species <- elliott_2018_data_raw$source[elliott_2018_data$index]
invaild_names <- c("Stream bait", "(Re) Pr-1556 from coast live oak log", "(Re) Pr-745 from Q. chrysolepis")
elliott_2018_data$host_species[elliott_2018_data$host_species %in% invaild_names] <- NA
elliott_2018_data$host_genus <- gsub(pattern = ' .+$', replacement = '', elliott_2018_data$host_species)

kasuga_2016_data_raw <- parse_and_standardize_tsv('data/metadata_references/kasuga_2016.tsv')
kasuga_2016_data_raw$isolate_numbers <- sub(kasuga_2016_data_raw$isolate_numbers, pattern = ' \\(.+\\)$', replacement = '')
kasuga_2016_data <- extract_data(table = kasuga_2016_data_raw, id_cols = c('isolate_numbers', 'other_numbers'), table_id = 'Kasuga et al. 2018')
kasuga_2016_data$year <- kasuga_2016_data_raw$year[kasuga_2016_data$index]
kasuga_2016_data$country <- ifelse(kasuga_2016_data_raw$county_or_country[kasuga_2016_data$index] == 'UK', 'UK', 'USA')
kasuga_2016_data$state <- ifelse(kasuga_2016_data_raw$county_or_country[kasuga_2016_data$index] == 'UK', NA, 'CA')
kasuga_2016_data$county <- ifelse(kasuga_2016_data_raw$county_or_country[kasuga_2016_data$index] == 'UK', NA, kasuga_2016_data_raw$county_or_country[kasuga_2016_data$index])
kasuga_2016_data$lineage <- 'NA1'
kasuga_2016_data$host_species <- sub(pattern = ', .+$', replacement = '', kasuga_2016_data_raw$source[kasuga_2016_data$index])
invaild_names <- c("rain water near infected U. californica")
kasuga_2016_data$host_species[kasuga_2016_data$host_species %in% invaild_names] <- NA
kasuga_2016_data$host_genus <- gsub(pattern = ' .+$', replacement = '', kasuga_2016_data$host_species)

# Nick: "University of exeter are likely david studholme's group. Ramorum metadata is in table 1 for lines 5-20 (https://www.sciencedirect.com/science/article/pii/S2213596017300247)"
turner_2017_data_raw <- parse_and_standardize_tsv('data/metadata_references/turner_2017.tsv')
turner_2017_data <- extract_data(table = turner_2017_data_raw, id_cols = c('isolate'), table_id = 'Turner et al. 2017')
turner_2017_data$year <- turner_2017_data_raw$year[turner_2017_data$index]
turner_2017_data$country <- 'UK'
turner_2017_data$state <- turner_2017_data_raw$county[turner_2017_data$index]
turner_2017_data$county <- turner_2017_data_raw$county[turner_2017_data$index]
turner_2017_data$lineage <- 'EU1'
turner_2017_data$host_species <- turner_2017_data_raw$source[turner_2017_data$index]
invaild_names <- c()
turner_2017_data$host_species[turner_2017_data$host_species %in% invaild_names] <- NA
turner_2017_data$host_genus <- gsub(pattern = ' .+$', replacement = '', turner_2017_data$host_species)

# Nick: "Univ of british columbia are richard hamelin's group, published in Dale 2019."
gl_data_raw <- parse_and_standardize_tsv('data/metadata_references/GL_no_record.tsv')
dale_2019_data_raw <- gl_data_raw[! is.na(gl_data_raw$center_name) & gl_data_raw$center_name == 'UNIVERSITY OF BRITISH COLUMBIA', ]
dale_2019_data <- extract_data(table = dale_2019_data_raw, id_cols = c('isolate_id'), table_id = 'Dale et al. 2019')
dale_2019_data$year <- dale_2019_data_raw$year[dale_2019_data$index]
dale_2019_data$country <- ifelse(dale_2019_data_raw$location[dale_2019_data$index] == "BC, Canada", "Canada", "France")
dale_2019_data$state <- ifelse(dale_2019_data_raw$location[dale_2019_data$index] == "BC, Canada", "British Columbia", NA)
dale_2019_data$county <- NA
dale_2019_data$lineage <- dale_2019_data_raw$lineage[dale_2019_data$index]
dale_2019_data$host_species <- dale_2019_data_raw$host[dale_2019_data$index]
invaild_names <- c('unknown')
dale_2019_data$host_species[dale_2019_data$host_species %in% invaild_names] <- NA
dale_2019_data$host_genus <- gsub(pattern = ' .+$', replacement = '', dale_2019_data$host_species)

# Nick: "sequenced in Jared's lab for Hazel's thesis. All from curry county forest."
daniels_2021_data_raw <- parse_and_standardize_tsv('data/metadata_references/curry_county.tsv')
daniels_2021_data <- extract_data(table = daniels_2021_data_raw, id_cols = 'id', table_id = 'Daniels 2021')
daniels_2021_data$year <- daniels_2021_data_raw$year[daniels_2021_data$index]
daniels_2021_data$country <- 'USA'
daniels_2021_data$state <- 'CA'
daniels_2021_data$county <- 'Curry'
daniels_2021_data$lineage <- daniels_2021_data_raw$lin[daniels_2021_data$index]
host_key <- c(
  "LIDE" = "Notholithocarpus densiflorus",
  "RHPU" = "Rhamnus purshiana",
  "VAOV" = "Vaccinium ovatum",
  "RHMA" = "Rhododendron macrophyllum",
  "UMCA" = "Umbellularia californica",
  "TODI" = "Toxicodendron diversilobum",
  "SOIL" = NA
)
stopifnot(all(daniels_2021_data_raw$host %in% names(host_key) | is.na(daniels_2021_data_raw$host)))
daniels_2021_data$host_species <- host_key[daniels_2021_data_raw$host]
daniels_2021_data$host_genus <- gsub(pattern = ' .+$', replacement = '', daniels_2021_data$host_species)

# Nick: " More work from Takao's group, published in Yuzon 2020."
yuzon_2020_xml <- read_xml('data/metadata_references/yuzon_2020.xml')
yuzon_2020_data_chr <- xml_attr(xml_find_all(yuzon_2020_xml, "//taxon"), "id")
yuzon_2020_data_chr <- yuzon_2020_data_chr[!is.na(yuzon_2020_data_chr)]
yuzon_2020_data_raw <- map_dfr(strsplit(yuzon_2020_data_chr, '_'), function(parts) {
  names(parts) <- c('id', 'location', 'year', 'host', 'tissue')
  as.data.frame(as.list(parts))
})
yuzon_2020_data <- extract_data(table = yuzon_2020_data_raw, id_cols = 'id', table_id = 'Yzon et al. 2020')
yuzon_2020_data$year <- yuzon_2020_data_raw$year[yuzon_2020_data$index]
yuzon_2020_data$country <- 'USA'
yuzon_2020_data$state <- 'CA'
yuzon_2020_data$county <- yuzon_2020_data_raw$location[yuzon_2020_data$index]
yuzon_2020_data$county <- gsub(yuzon_2020_data$county, pattern = '-', replacement = ' ')
yuzon_2020_data$lineage <- 'NA1'
yuzon_2020_data$host_species <- yuzon_2020_data_raw$host[yuzon_2020_data$index]
yuzon_2020_data$host_species <- gsub(pattern = '-', replacement = ' ', yuzon_2020_data$host_species)
invaild_names <- c('rainwater', 'stream')
yuzon_2020_data$host_species[yuzon_2020_data$host_species %in% invaild_names] <- NA
yuzon_2020_data$host_genus <- gsub(pattern = ' .+$', replacement = '', yuzon_2020_data$host_species)

combined_ref_data <- tibble::as_tibble(rbind(
  elliott_2018_data,
  kasuga_2016_data,
  turner_2017_data,
  dale_2019_data,
  daniels_2021_data,
  yuzon_2020_data
))
combined_ref_data$year <- as.numeric(combined_ref_data$year)

# Make empty chars NA
combined_ref_data[] <- lapply(combined_ref_data[], function(x) ifelse(x == '', NA, x))

# When multiple ID columns match an ID, check that they have the same metadata
n_unique_meta <- sapply(split(combined_ref_data, combined_ref_data$id), function(part) {
  nrow(unique(part[, ! colnames(part) %in% c('source','col', 'index')]))
})
non_unique_ids <- names(n_unique_meta[n_unique_meta > 1])
non_unique_data <- combined_ref_data[combined_ref_data$id %in% non_unique_ids, ]
non_unique_data <- non_unique_data[order(non_unique_data$id), ]
non_unique_data # Only one sample had a difference in metadata between sources, 2004 vs 2003.

# When IDs are included in multiple datasets, choose the oldest to be the source
combined_ref_data$publication_year <- as.numeric(sub(combined_ref_data$source, pattern = '.+ ([0-9]{4})$', replacement = '\\1'))
combined_ref_data <- map_dfr(split(combined_ref_data, combined_ref_data$id), function(part) {
  unique_id_data <- unique(part[, ! colnames(part) %in% c('col', 'index')])
  unique_id_data[which.min(unique_id_data$publication_year), , drop = FALSE]
})
stopifnot(nrow(combined_ref_data) == length(unique(combined_ref_data$id)))

# Use combined reference metadata when available
stopifnot(all(combined_ref_data$id %in% metadata$strain))
metadata$source <- 'Culture collection'
common_cols <- colnames(combined_ref_data)[colnames(combined_ref_data) %in%  colnames(metadata)]
for (col in common_cols) {
  non_na_subset <- combined_ref_data[!is.na(combined_ref_data[[col]]) & !combined_ref_data[[col]] == '', , drop = FALSE]
  metadata[match(non_na_subset$id, metadata$strain), col] <- non_na_subset[[col]]
}

# Remove invalid genus data
metadata$host_genus <- ifelse(
  metadata$host_genus %in% c('unknown', 'Soil'),
  NA,
  metadata$host_genus
)

# Replace sp./spp/sp/nothing in genus with "Other" 
metadata$host_species[grepl(metadata$host_species, pattern = ' sp|spp|sp\\.$')] <- 'Other'
metadata$host_species[grepl(metadata$host_species, pattern = '^ *[a-zA-Z]+ *$')] <- 'Other'

# Add reference to the metadata file so that its date can be controlled
metadata <- rbind(rep(NA, ncol(metadata)), metadata)
metadata$strain[1] <- ref_header[1]
metadata$year[1] <- 2016
metadata$country[1] <- 'USA'
metadata$state[1] <- 'CA'

# fix date format
metadata$date <- paste0(metadata$year, '-01-01')

# Clean up place names so it is easier to look up coordinates
replace_key <- c(
  "USA" = 'United States',
  "N.Ireland" = "Ireland",
  "UK" = "United Kingdom",
  "CA" = "California",
  "OR" = "Oregon", 
  "NC" = "North Carolina",
  "SC" = "South Carolina", 
  "WA" = "Washington",
  "GA" = "Georgia",
  "MS" = "Mississippi"
)
metadata$country[metadata$country %in% names(replace_key)] <- replace_key[metadata$country[metadata$country %in% names(replace_key)]]
metadata$state[metadata$state %in% names(replace_key)] <- replace_key[metadata$state[metadata$state %in% names(replace_key)]]

# Check if any rows have coordinates but no placenames
any(is.na(metadata$country) & (!is.na(metadata$gps_coord) & !is.na(metadata$lat)))
any(is.na(metadata$state) & (!is.na(metadata$gps_coord) & !is.na(metadata$lat)))

# Make coordinate file
options(geonamesUsername = "fosterz")
get_coords <- function(name, group, country = NULL, ...) {
  res <- geonames::GNsearch(name_equals = name, ...)
  if (!is.null(country) && "countryName" %in% colnames(res)) {
    res <- res[res$countryName == country, , drop = FALSE]
  }
  res <- res[order(as.numeric(res$population), decreasing = TRUE)[1], ]
  out <- data.frame(group = group, name = name, lat = res$lat, lon = res$lng, stringsAsFactors = FALSE)
  return(out)
}

coord_data <- rbind(
  map_dfr(unique(metadata$country[!is.na(metadata$country)]), get_coords, group = 'Country'),
  map_dfr(unique(metadata$state[!is.na(metadata$state) & metadata$country == 'United States']), get_coords, group = 'State', country = 'United States'),
  map_dfr(unique(metadata$state[!is.na(metadata$state) & metadata$country == 'United Kingdom']), get_coords, group = 'State', country = 'United Kingdom')
)

# Add country names to state variable when a state is not available
metadata$state <- ifelse(is.na(metadata$state) | metadata$state == '', metadata$country, metadata$state)
country_as_state <- coord_data[coord_data$group == 'Country', ]
country_as_state$group <- 'State'
coord_data <- rbind(coord_data, country_as_state)

# Make dropped strains file
missing_country <- is.na(metadata$country) | metadata$country == ''
invalid_date <- is.na(metadata$year) | metadata$year > 2025 | metadata$year < 1600
missing_seq <- ! metadata$strain %in% c(ref_header, sample_headers)
dropped_ids <- metadata$strain[missing_country | invalid_date | missing_seq]
writeLines(dropped_ids, con = args$dropped_out)

# Capitalize some column names for display purposes
colnames(metadata)[colnames(metadata) == 'state'] <- 'State'
colnames(metadata)[colnames(metadata) == 'country'] <- 'Country'

# Subset coord_data to just places present in metadata after filtering
coord_data <- map_dfr(split(coord_data, coord_data$group), function(part) {
  part[part$name %in% metadata[[part$group[1]]], ]
})

# Write coordinate file
write.table(coord_data, file = args$coordinate_out,
            col.names = FALSE, row.names = FALSE, na = '', sep = '\t', quote = FALSE)


# Remove dropped strains from metadata file since Nextstrain does not seem to always ignore them
metadata <- metadata[! metadata$strain %in% dropped_ids, , drop = FALSE]

# Rename rare categories to "other"
condense_rare <- function(values, max_count) {
  counts <- table(values)
  if (length(counts) > max_count) {
    common <- names(sort(counts, decreasing = TRUE))[seq_len(max_count - 1)]
    values[! values %in% common] <- 'Other'
  }
  values
}
metadata$host_genus <- condense_rare(metadata$host_genus, args$max_colors)
metadata$host_species <- condense_rare(metadata$host_species, args$max_colors)
metadata$lineage <- condense_rare(metadata$lineage, args$max_colors)


# Save metadata file
write.table(metadata, file = args$metadata_out,
            col.names = TRUE, row.names = FALSE, na = '', sep = '\t', quote = FALSE)

# Make color file
color_data <- coord_data[, c('group', 'name')]
color_data <- do.call(rbind, lapply(split(color_data, color_data$group), function(part) {
  group <- part$group[1]
  ordered_values <- names(sort(table(metadata[[group]]), decreasing = TRUE))
  ordered_values <- ordered_values[ordered_values %in% part$name]
  part <- part[match(ordered_values, part$name), ]
  if (nrow(part) > args$max_colors) {
    part$color <- c(viridis(args$max_colors, direction = -1), rep('#555555FF', nrow(part) - args$max_colors))
  } else {
    part$color <- viridis(nrow(part), direction = -1)
  }
  return(part)
}))

other_color_data <- map_dfr(c('host_genus', 'host_species', 'lineage'), function(col) {
  ordered_values <- names(sort(table(metadata[[col]]), decreasing = TRUE))
  if ('Other' %in% ordered_values) {
    ordered_values <- c(ordered_values[ordered_values != 'Other'], 'Other')
  }
  data.frame(
    group = col,
    name = ordered_values,
    color = c(viridis(length(ordered_values) - 1, direction = -1), '#555555FF'),
    stringsAsFactors = FALSE
  )
})
color_data <- rbind(color_data, other_color_data)

color_data$color <- substr(color_data$color, start = 1, stop = 7)
write.table(color_data, file = args$color_out,
            col.names = TRUE, row.names = FALSE, na = '', sep = '\t', quote = FALSE)

