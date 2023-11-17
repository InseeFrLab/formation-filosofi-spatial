rm(list=ls())
gc()

library(readxl)
library(dplyr)
library(ggplot2)
library(sf)
library(mapsf)


## Importer les données Filosofi

url <- c("https://www.insee.fr/fr/statistiques/fichier/6692392/base-cc-filosofi-2020_XLSX.zip")

temp <- tempfile()
temp2 <- tempfile()

download.file(url, temp)

unzip(zipfile = temp, exdir = temp2)

filo <- readxl::read_xlsx(file.path(temp2, "base-cc-filosofi-2020-geo2023.xlsx"), 
                          sheet = "COM", 
                          skip = 5) %>%
  dplyr::select(CODGEO, LIBGEO, TP6020) %>%
  dplyr::mutate(TP6020 = as.numeric(gsub(pattern = ",", replacement = ".", x = TP6020)))
colnames(filo) <- tolower(colnames(filo))

unlink(c(temp, temp2))
rm(url, temp, temp2)


## Importer les contours des AAV

url <- c("https://www.insee.fr/fr/statistiques/fichier/4803954/fonds_aav2020_2023.zip")

temp <- tempfile()
temp2 <- tempfile()
temp3 <- tempfile()

download.file(url, temp)

unzip(zipfile = temp, exdir = temp2)

zipfiles <- list.files(temp2)

unzip(zipfile = file.path(paste(temp2, zipfiles[2], sep = "\\")), exdir = temp3)


## Importer shapefile

shp_com <- st_read(dsn = temp3,
                   layer = "com_aav2020_2023")

unlink(c(temp, temp2, temp3))
rm(url, temp, temp2, temp3)


## Restriction AAV

# Quelques exemples d'AAV qui marchent "bien"
AAV <- c("Marseille - Aix-en-Provence")
AAV <- c("Strasbourg (partie française)")
AAV <- c("Angers")
AAV <- c("Poitiers")
AAV <- c("Lyon")
AAV <- c("Rennes")


## Merge des données

don <- shp_com %>% 
  dplyr::filter(libaav2020 == AAV) %>%
  left_join(filo, by = c("codgeo", "libgeo"))


## Récupérer les contours du pôle de l'AAV pour l'afficher en rouge sur la carte

contours_pole <- don %>% 
  dplyr::filter(cateaav != "Commune de la couronne") %>%
  st_union()


## Carte AAV

mf_theme("default")
par(mfrow=c(1,1))
mf_map(
  x= don,
  var = "tp6020", 
  border = "white",
  leg_no_data = "Secret statistique",
  type = "choro",
  breaks = c(5,8,12,16,max(don$tp6020, na.rm = T)),
  col_na = "grey", 
  leg_title = "Taux de pauvreté"
  ) 
plot(contours_pole, border = "red",lwd = 2, add = T)

mf_layout(
  title = paste("Taux de pauvreté des communes de l'AAV de", AAV),
  credits = "",
  arrow = F
)
