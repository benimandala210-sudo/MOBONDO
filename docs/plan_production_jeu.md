# MOBONDO — Plan de production du jeu

Version 1.0 — Décision de production

## Décision

MOBONDO quitte la logique de démonstration technique. Les prochaines livraisons doivent constituer un jeu cohérent, avec des ressources graphiques réelles, une architecture maintenable et des critères de validation sur Android.

La version actuellement installée est une preuve de démarrage et de contrôle. Elle n'est pas une référence de qualité visuelle ni une base à enrichir indéfiniment.

## Audit de départ

Constats sur le dépôt au 12 novembre 2026 :

- Le monde est principalement construit par code dans `scripts/main.gd` (environ 1 312 lignes).
- La scène principale est presque vide et délègue l'essentiel à ce script.
- Le joueur est un `CapsuleMesh` bleu créé à l'exécution.
- Le taxi, les éléments de décor et plusieurs objets sont des primitives géométriques.
- Le dépôt ne contient pas de bibliothèque de modèles 3D, de textures de décor, d'animations de personnage ou de banque audio de jeu.
- Les systèmes de mission, dialogue et économie existent déjà sous forme de scripts séparés, mais leur intégration dépend encore du script principal.
- Les documents géographiques et artistiques de Mapela–Raïs constituent une base de conception ; ils ne certifient pas les positions exactes des rues ou des parcelles.

Conséquence : améliorer seulement les couleurs ou ajouter d'autres cubes ne répondrait pas à l'objectif. Il faut produire et intégrer de véritables ressources, puis séparer les responsabilités du jeu.

## Direction artistique à respecter

- Monde urbain inspiré de Kinshasa, crédible et quotidien.
- Direction audiovisuelle FUSION : cadrage cinématographique, énergie authentique de la ville et émotion humaine.
- Palette de marque : noir urbain `#17191D`, terre kinoise `#C58A42`, sable `#D9C8A4`, vert tropical `#386B48`.
- Matériaux, architecture, vêtements, véhicules et végétation cohérents avec le contexte local.
- Pas de clichés visuels, de décor mafieux dominant ou d'enseignes privées réelles sans autorisation.
- Interface et dialogues d'abord en lingala kinois ; français comme langue secondaire à intégrer proprement.
- Le slogan reste : « UN MONDE. UNE VIE. TA PROPRE HISTOIRE. »

## Architecture cible du projet

Le code doit évoluer vers des scènes et systèmes autonomes, sans conserver un unique script géant comme centre du jeu.

```
scenes/
  boot/
  world/
    mapela_rais/
  characters/
    player/
    npc/
  vehicles/
  buildings/
  ui/
  menus/
scripts/
  core/
  world/
  player/
  npc/
  vehicles/
  missions/
  dialogue/
  economy/
  save/
  ui/
assets/
  characters/
  environment/
  buildings/
  roads/
  vehicles/
  materials/
  textures/
  animations/
  audio/
docs/
```

Les scènes sont responsables de leur représentation ; les systèmes gèrent les règles de jeu. Les données de quartier, les dialogues et les missions doivent être séparés du code de présentation.

## Premier jalon de production : tranche verticale Mapela–Raïs

La première vraie livraison jouable doit être une petite portion cohérente et reconnaissable du quartier, pas une grande carte vide.

### Contenu obligatoire

1. Un personnage humain complet, avec squelette, animations de repos, marche et course, proportions et vêtements crédibles.
2. Une caméra troisième personne stable, cadrage lisible et commandes tactiles confortables.
3. Un morceau de quartier construit avec des modèles et matériaux finalisés : maisons, murs, portes, toitures, route, ruelles, végétation et mobilier urbain.
4. Un axe principal et des repères de Mapela validés progressivement avec les informations locales.
5. Raïs représenté par les anciennes traces de fer discontinues ; aucun train ne circule dans cette zone.
6. Une ambiance sonore urbaine originale et discrète, avec variations selon les lieux.
7. Une interface mobile cohérente avec l'identité MOBONDO, lisible sur écran Android.
8. Une interaction réelle avec au moins un habitant et un lieu du quartier.

### Règles géographiques

- Ne pas inventer les intersections, les distances ou les limites de parcelles.
- Conserver les noms documentés sans placer une rue de façon arbitraire lorsque son tracé n'est pas confirmé.
- Distinguer les repères observés localement des approximations de gameplay.
- Les retours du concepteur local priment sur une hypothèse cartographique générique.
- Les établissements privés utilisent des noms fictifs par défaut ; les établissements publics peuvent garder leur nom officiel.

## Pipeline des ressources

Chaque ressource 3D doit avoir une provenance claire : création originale, ressource libre avec licence vérifiée ou ressource sous licence acquise. Les licences et crédits sont consignés dans le dépôt.

Priorité des ressources :
1. personnage joueur et animations ;
2. kit architectural cohérent pour les maisons et parcelles ;
3. routes, sols, murs, portes, fenêtres et toitures ;
4. végétation, mobilier et accessoires de rue ;
5. véhicules et personnages secondaires ;
6. audio d'ambiance et interface.

Aucune image 2D présentée comme une capture du jeu, aucun rendu conceptuel présenté comme un modèle 3D jouable, et aucun asset temporaire ne doit être présenté comme une livraison finale.

## Cibles techniques Android

- Moteur : Godot 4.2.2 au départ ; toute mise à niveau doit être testée et justifiée.
- Rendu : compatibilité mobile, en privilégiant la stabilité et le coût GPU.
- Cible de référence initiale : appareil Android modeste, 2 Go de RAM.
- Prévoir niveaux de détail, textures compressées, éclairage maîtrisé, distance d'affichage et densité NPC réglables.
- Mesurer la fluidité, la mémoire et les temps de chargement sur appareil réel ; ne pas déclarer l'optimisation réussie sur la seule base d'un test headless.
- Un build réussi ne signifie pas que l'expérience visuelle et les contrôles sont validés.

## Critères d'acceptation de chaque livraison

Une livraison n'est considérée comme prête que si :

- les scripts passent la validation sans erreur GDScript ;
- le projet s'ouvre et la scène principale s'exécute ;
- les ressources attendues sont réellement présentes dans le paquet ;
- l'APK s'installe et démarre sur l'appareil de référence ;
- les contrôles tactiles et la caméra sont testés ;
- aucun écran noir, objet manquant ou interface bloquée n'est observé ;
- les limites connues sont annoncées explicitement.

## Ordre de travail

1. Assainir et modulariser le projet sans casser les systèmes déjà fonctionnels.
2. Définir le pipeline des ressources et intégrer les premiers vrais assets sous licence vérifiée.
3. Produire le personnage joueur complet et son contrôleur troisième personne.
4. Construire un premier secteur finalisé de Mapela–Raïs.
5. Intégrer les habitants, les interactions et l'ambiance sonore.
6. Refaire l'interface et les transitions.
7. Tester et optimiser sur Android avant d'étendre la carte.

## Règle de communication

Ne jamais qualifier de « terminé », « réaliste », « optimisé » ou « testé sur Android » un élément qui n'a pas réellement satisfait ses critères. Une étape technique est une étape technique ; elle ne doit pas être présentée comme une livraison artistique finale.
