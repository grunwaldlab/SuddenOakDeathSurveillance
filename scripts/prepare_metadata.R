# Format input files

# Load libraries
library(viridis)
library(geonames)
library(argparser)

# Parse command line arguments
parser <- arg_parser("Format input files for phylogenetic analysis with augur tools")
parser <- add_argument(parser, "--metadata", help="Input metadata TSV file", default="data/Pram_MetaData.tsv")
parser <- add_argument(parser, "--samples", help="Input sample FASTA file", default="data/global_n661_mt.fasta")
parser <- add_argument(parser, "--reference", help="Input reference FASTA file", default="data/mtMartin2007_PR-102_v3.1.mt.fasta")
parser <- add_argument(parser, "--metadata_out", help="Output modified metadata TSV file", default="data/metadata_modified.tsv")
parser <- add_argument(parser, "--coordinate_out", help="Output coordinate TSV file", default="data/lat_longs.tsv")
parser <- add_argument(parser, "--color_out", help="Output color TSV file", default="data/colors.tsv")
parser <- add_argument(parser, "--dropped_out", help="Output dropped strains file", default="data/dropped_strains.txt")
args <- parse_args(parser)

# Parse input files
metadata <- read.csv(args$metadata, check.names = FALSE)
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

# Add genus to species name
metadata$host_species <- ifelse(
  is.na(metadata$host_genus) | is.na(metadata$host_species),
  NA, 
  paste(metadata$host_genus, metadata$host_species)
)

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
  "N.Ireland" = "Ireland"
)
metadata$country[metadata$country %in% names(replace_key)] <- replace_key[metadata$country[metadata$country %in% names(replace_key)]]

# Make coordinate file
options(geonamesUsername = "fosterz")
get_coords <- function(name, group, ...) {
  res <- geonames::GNsearch(name_equals = name, ...)  
  if ("fcode" %in% colnames(res)) {
    res <- res[res$name == name & res$fcode %in% c("AREA", "PCLI", "ADM1"), , drop = FALSE]
  }
  res <- res[1, ]
  out <- data.frame(group = group, name = name, lat = res$lat, lon = res$lng, stringsAsFactors = FALSE)
  return(out)
}
coord_data <- do.call(rbind, c(
  lapply(unique(metadata$country, na.rm = TRUE), get_coords, group = 'Country'),
  lapply(unique(metadata$state), get_coords, group = 'State', country = 'USA', fcode = "ADM1")
))
coord_data <- coord_data[coord_data$name != "" & ! is.na(coord_data$name), ]


# Add country names to state variable when a state is not available
metadata$state <- ifelse(is.na(metadata$state), metadata$country, metadata$state)
country_as_state <- coord_data[coord_data$group == 'Country', ]
country_as_state$group <- 'State'
coord_data <- rbind(coord_data, country_as_state)

# Write coordinate format
write.table(coord_data, file = args$coordinate_out,
            col.names = FALSE, row.names = FALSE, na = '', sep = '\t')

# Make dropped strains file
missing_country <- is.na(metadata$country)
invalid_date <- is.na(metadata$year) | metadata$year > 2025 | metadata$year < 1600
missing_seq <- ! metadata$strain %in% c(ref_header, sample_headers)
dropped_ids <- metadata$strain[missing_country | invalid_date | missing_seq]
writeLines(dropped_ids, con = args$dropped_out)

# Remove dropped strains from metadata file since Nextstrain does not seem to always ignore them
metadata <- metadata[! metadata$strain %in% dropped_ids, , drop = FALSE]

# Capitalize some column names for display purposes
colnames(metadata)[colnames(metadata) == 'state'] <- 'State'
colnames(metadata)[colnames(metadata) == 'country'] <- 'Country'

# save metadata file
write.table(metadata, file = args$metadata_out,
            col.names = TRUE, row.names = FALSE, na = '', sep = '\t')

# Make color file
color_data <- coord_data[, c('group', 'name')]
color_data$color <- viridis(nrow(color_data))
color_data$color <- substr(color_data$color, start = 1, stop = 7)
write.table(color_data, file = args$color_out,
            col.names = TRUE, row.names = FALSE, na = '', sep = '\t')