#### SUS GLOBALS ###############################################################


# Platform dependant ------------------------------------------------------

site_name <- "Curbcut Vancouver"
city_name <- "Vancouver"
site_url <- "https://vancouver.curbcut.ca"
stories_page <- "Vancouver stories"
tileset_prefix <- "van"
mapbox_username <- "sus-mcgill"

default_region <- "CMA"
# For a location lock placeholder in advanced options
default_random_address <- "4600 Cambie St, Vancouver, BC"

map_zoom <- 9.1
map_loc <- c(-122.77, 49.22)

# Packages ----------------------------------------------------------------

suppressPackageStartupMessages({
  library(curbcut)
  
  library(shiny)
  library(bslib)
  library(shinyjs)
  
  library(qs)
  library(glue)
  library(metathis)
  
  library(stringr)
  library(DBI)
  library(RSQLite)
  
  library(sever)
})

# Shiny options -----------------------------------------------------------

options(shiny.fullstacktrace = TRUE)
options(shiny.useragg = TRUE)
shinyOptions(cache = cachem::cache_disk(file.path(dirname(tempdir()), "cache")))


# Data --------------------------------------------------------------------

# Load all .qs and .qsm files that are in the root of the data folder
data_files <- list.files("data", full.names = TRUE)
invisible(lapply(data_files[grepl("qsm$", data_files)], 
                 qs::qload, env = .GlobalEnv))
invisible(lapply(data_files[grepl("qs$", data_files)], 
                 \(x) {
                   object_name <- gsub("(data/)|(\\.qs)", "", x)
                   assign(object_name, qs::qread(x), envir = .GlobalEnv)
                 }))


# Connect to the dbs ------------------------------------------------------

dbs <- list.files("data", full.names = TRUE)
dbs <- subset(dbs, grepl(".sqlite$", dbs))

lapply(dbs, \(x) {
  connection_name <- paste0(stringr::str_extract(x, "(?<=/).*?(?=\\.)"), "_conn")
  assign(connection_name, dbConnect(SQLite(), x), envir = .GlobalEnv)
}) |> invisible()


# Modules ready -----------------------------------------------------------

unique_themes <- unique(modules$theme)[!is.na(unique(modules$theme))]
display_mods <- modules[!is.na(modules$theme), ]
mods_rdy <- 
  sapply(unique_themes, \(x) {
    thm <- display_mods[display_mods$theme == x, ]
    ids <- thm$id
    names(ids) <- thm$nav_title
    ids
  }, simplify = FALSE, USE.NAMES = TRUE)


# Grab all place explorer documents ---------------------------------------

pe_docs <- list.files("www/place_explorer/")


# Map defaults ------------------------------------------------------------

map_token <- paste0("pk.eyJ1Ijoic3VzLW1jZ2lsbCIsImEiOiJjbDBxMTcyNWwyNTl0M2",
                    "RtZzRremNxOHA3In0.V2Ah5lxy-3RZlF2QKOvIjg")
options(rdeck.mapbox_access_token = map_token)
map_base_style <- "mapbox://styles/sus-mcgill/cl0reqoz4000z15pekuh48ld6"
map_style_building <- "mapbox://styles/sus-mcgill/cl2bwtrsp000516rwyrkt9ior"

first_level_choropleth <- 
  sapply(ls()[grepl("map_zoom_levels_", ls())], \(x) names(get(x)[1]),
         USE.NAMES = FALSE) |> unique()

all_choropleths <- 
  sapply(sapply(ls()[grepl("map_zoom_levels_", ls())], get, USE.NAMES = FALSE), 
         names, USE.NAMES = FALSE) |> unlist() |> unique()

# Set up fonts ------------------------------------------------------------

systemfonts::register_font(
  name = "SourceSansPro",
  plain = "www/fonts/SourceSansPro-Regular.ttf",
  italic = "www/fonts/SourceSansPro-Italic.ttf",
  bold = "www/fonts/SourceSansPro-Bold.ttf",
  bolditalic = "www/fonts/SourceSansPro-BoldItalic.ttf")


# Declare temporary folder ------------------------------------------------

temp_folder <- tempdir()
addResourcePath("temp_folder_shortcut", temp_folder)


# Create the UI and server functions for basic modules --------------------

curbcut::create_ui_server_mods(modules = modules)
