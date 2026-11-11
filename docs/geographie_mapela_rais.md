# Géographie de MOBONDO — Mapela–Raïs

## Statut de la reconstruction

La zone de départ de MOBONDO est Mapela–Raïs, commune de Masina, Kinshasa.
Cette carte est une reconstitution de jeu en 3D stylisée, et non un relevé cadastral ou un plan topographique certifié.

Règle de production :
- Les noms de rues documentés sont conservés.
- Une rue dont la position exacte n'est pas vérifiée peut être nommée dans le jeu, mais son tracé reste à confirmer.
- Les connexions OSM disponibles peuvent servir de point de départ, sans prétendre remplacer la connaissance des habitants.
- Les éléments propres à Raïs rapportés par les habitants priment sur les hypothèses cartographiques génériques.

## Repères géographiques documentés

- Le point cartographique OSM de la localité Mapela est situé approximativement à -4.38406, 15.39215. Cette coordonnée est un repère de localité, pas le centre exact de toutes les activités du quartier.
- La route/avenue Bilonda est située à Mapela. L'ACP la décrit comme un axe important, emprunté quotidiennement par les habitants et les vendeuses du marché, et sensible aux pluies.
- La fiche OSM/OpenAlfa de Frontiere indique deux rues adjacentes : Avenue Bilonda et Rue Imbali. Elle décrit Frontiere comme une rue résidentielle avec surface en terre/boue et sans trottoir.
- La gare cartographiée « Masina Mapela » existe dans les données OSM à proximité. Sa présence cartographique ne doit pas être interprétée comme la preuve qu'un train dessert Raïs.

## Noms de rues répertoriés à Mapela

Les noms ci-dessous sont enregistrés comme répertoire de rues. Leur position précise n'est pas encore validée pour chacun :

- Avenue Bilonda
- Frontiere
- Kahumba
- Lufushi
- Muteba
- Ngufulu
- Ntalu 1
- Ntalu 2
- Rue Fatuma
- Rue Frontiere
- Rue Imbali
- Rue Inzia
- Rue Justice
- Rue Kikwit
- Rue Kotoko
- Rue Kulu
- Rue Mbula
- Rue Milundu
- Rue Ntalu
- Rue Travail
- Salongo
- Yassa

Attention : « Frontiere » et « Rue Frontiere » sont conservés tels qu'ils apparaissent dans le répertoire. Il faudra confirmer s'il s'agit de deux voies distinctes ou de variantes de nom.

## Connexions cartographiques retenues avec prudence

La donnée ouverte consultée indique :
- Frontiere est connectée à Avenue Bilonda.
- Frontiere est connectée à Rue Imbali.

Dans le prototype, ces trois voies sont représentées par un petit réseau provisoire pour rendre la zone jouable. Le tracé et les distances sont approximatifs et devront être corrigés au fur et à mesure de la validation locale.

## Raïs et les anciennes traces ferroviaires

Raïs est une partie de Mapela identifiée localement par les anciens morceaux de fer laissés par le passage du train. Selon la précision fournie par le connaisseur local du quartier, le train ne circule plus dans cette zone de Raïs.

Décision de représentation :
- montrer des morceaux de fer anciens, discontinus et partiellement enfouis comme repère de quartier ;
- ne pas faire circuler de train à Raïs ;
- ne pas confondre ce repère local avec la gare cartographiée Masina Mapela ;
- ne pas supposer l'orientation ou les coordonnées exactes des morceaux de fer avant validation supplémentaire.

## Implémentation actuelle dans le prototype

Dans `scripts/main.gd` :
- Avenue Bilonda est utilisée comme axe principal provisoire du petit niveau jouable ;
- Frontiere et Imbali ont un tracé provisoire fondé sur leur connexion cartographique connue ;
- un panneau de répertoire présente les noms des rues sans attribuer une position à celles qui ne sont pas localisées ;
- Raïs possède un repère visuel de morceaux de fer anciens, sans train ;
- les rues, distances, orientations et limites de parcelles restent à ajuster avec des informations locales plus précises.

## Sources publiques consultées

- OpenAlfa, annuaire des rues de Mapela : https://rues-rd-congo.openalfa.com/mapela
- OpenAlfa, fiche Frontiere et rues adjacentes : https://rues-rd-congo.openalfa.com/rues/frontiere-masina-kinshasa-republique-democratique-du-congo
- ACP, lancement des travaux d'aménagement de la route Bilonda, 7 janvier 2026 : https://acp.cd/urbain/kinshasa-lancement-des-travaux-damenagement-de-la-route-bilonda-a-masina/
- Mapcarta / OpenStreetMap, localité Mapela : https://mapcarta.com/fr/N667167678
- Mapcarta / OpenStreetMap, gare cartographiée Masina Mapela : https://mapcarta.com/fr/N715964332

---
Document de travail géographique. Les données ouvertes sont incomplètes et doivent être confrontées à la connaissance du terrain avant toute affirmation de géométrie exacte.
