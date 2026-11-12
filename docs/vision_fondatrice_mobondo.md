# Vision fondatrice de MOBONDO

> **UN MONDE. UNE VIE. TA PROPRE HISTOIRE.**

Ce document est la boussole de conception de MOBONDO. Chaque fonctionnalité, chaque quartier, chaque personnage et chaque choix technique doit renforcer cette vision. Une fonctionnalité isolée ne doit jamais détourner le projet de son identité.

## 1. Le jeu que nous construisons

MOBONDO est un jeu vidéo de simulation de vie en monde ouvert, ancré dans la réalité quotidienne de Kinshasa, en République démocratique du Congo. Le joueur incarne un adulte qui commence sa propre vie à Mapela–Raïs, dans la commune de Masina.

Ce n'est ni un simple jeu de commerce, ni un jeu de missions successives, ni un simulateur de criminalité. C'est un monde dans lequel le joueur construit librement sa propre histoire.

## 2. Liberté du joueur

Le joueur doit pouvoir choisir ses priorités et changer de direction à tout moment :
- chercher un emploi, travailler, apprendre un métier et progresser ;
- créer une activité, gérer un commerce, développer une entreprise ;
- louer ou acquérir un logement, aménager son espace et construire un foyer ;
- nouer des amitiés, entretenir des relations et fonder une famille ;
- se déplacer à pied, à moto, en taxi et avec les transports disponibles ;
- participer à la vie du quartier, se divertir, faire du sport, se reposer ;
- poursuivre ses ambitions personnelles, explorer et simplement vivre son quotidien.

Les missions et activités sont des possibilités, jamais une obligation permanente. Le mode libre doit rester réellement libre. La criminalité ne doit jamais être présentée comme le cœur ou la voie obligatoire du jeu.

## 3. Un monde vivant et crédible

Le quartier ne doit pas être un décor vide. Il doit évoluer et réagir :
- habitants et personnages non-joueurs avec des identités, des routines, des besoins et des relations ;
- circulation, piétons, taxis, motos, transports et interactions cohérentes ;
- commerces, marchés, services publics, écoles, lieux de culte, espaces de sport et lieux de rencontre ;
- alternance jour/nuit, météo et rythme des activités ;
- économie locale avec emplois, revenus, dépenses, prix, stocks, clients et entreprises ;
- conséquences lisibles des décisions du joueur sur sa situation et ses relations.

La priorité est la cohérence et la profondeur des systèmes, pas l'accumulation de boutons ou de fonctionnalités artificielles.

## 4. Identité kinoise et respect du terrain

Mapela–Raïs est le premier territoire jouable. Raïs est une partie de Mapela et doit conserver les repères locaux communiqués par les habitants. Les anciens morceaux de fer liés au passage du train constituent un repère ; le train ne circule plus dans cette zone.

La culture, les expressions, les habitudes, les rythmes et les réalités de Kinshasa doivent être représentés avec respect. Le lingala kinois est la langue principale de l'expérience et des dialogues ; le français est une option complémentaire.

Les lieux publics peuvent conserver leurs dénominations officielles. Les commerces privés utilisent des noms fictifs par défaut. Une entreprise privée réelle, son nom, son logo ou son identité ne peut être intégrée qu'avec une autorisation explicite et un partenariat convenu. Aucun faux partenariat ni publicité gratuite ne doit être créé.

## 5. Principes de conception

1. **La vie avant les missions :** le joueur doit avoir des choses intéressantes à faire même sans objectif imposé.
2. **La liberté avant les rails :** les systèmes doivent permettre plusieurs styles de vie et plusieurs trajectoires.
3. **La crédibilité avant le remplissage :** chaque activité doit avoir une raison d'exister et des conséquences cohérentes.
4. **Le quartier avant la carte géante vide :** construire d'abord Mapela–Raïs avec une vraie densité de vie, puis étendre le monde progressivement.
5. **La profondeur avant la quantité :** améliorer les interactions, l'IA des habitants, l'économie et les routines plutôt que multiplier les systèmes superficiels.
6. **L'accessibilité :** viser une expérience Android fluide, avec commandes tactiles lisibles et performances maîtrisées.
7. **L'évolutivité :** concevoir les systèmes pour permettre plus tard l'ajout de quartiers, de métiers, de véhicules, de contenus et éventuellement du multijoueur, sans promettre une fonction non construite.
8. **L'honnêteté technique :** distinguer clairement code enregistré, validation de projet, compilation, export APK et tests réels sur appareil.

## 6. Ordre de développement directeur

Les étapes peuvent se chevaucher, mais chaque bloc doit renforcer le monde commun :

- **Fondations jouables :** déplacement, caméra, sauvegarde, interface et commandes mobiles fiables.
- **Quartier crédible :** routes, bâtiments, repères locaux, circulation et environnement de Mapela–Raïs.
- **Vie quotidienne :** besoins, temps, météo, routines, conversations et relations des habitants.
- **Économie complète :** emplois, achats, ventes, clients, stocks, prix, commerces indépendants et entreprises du joueur.
- **Vie personnelle :** logement, amitiés, famille, loisirs, santé et progression personnelle.
- **Mobilité et services :** véhicules, transports publics, services et déplacements cohérents.
- **Polissage :** modèles, animations, sons, effets, optimisation Android, interface et tests.

Le système économique en cours n'est donc qu'un pilier parmi d'autres. Il doit s'intégrer à la vie des habitants, aux besoins du joueur, aux déplacements et à l'évolution du quartier.

## 7. Questions obligatoires avant toute nouvelle fonctionnalité

Avant d'ajouter un système, vérifier :
- Est-ce que cela enrichit la simulation de vie à Kinshasa ?
- Est-ce que le joueur garde le choix de l'utiliser ou non ?
- Est-ce cohérent avec Mapela–Raïs et les autres systèmes déjà présents ?
- Est-ce que cela crée une interaction ou une conséquence réelle, plutôt qu'un simple décor ?
- Est-ce adapté aux capacités et aux performances visées sur Android ?
- Est-ce conforme à la règle commerciale et au respect des lieux/personnes réels ?

Si la réponse est non, la fonctionnalité doit être repensée, reportée ou écartée.

---

**Règle de conduite du projet :** ne jamais confondre une fonctionnalité en cours avec la vision entière de MOBONDO. Chaque développement doit contribuer à un monde ouvert vivant où le joueur peut travailler, aimer, apprendre, entreprendre, se déplacer, se reposer, rencontrer des gens et écrire librement sa propre histoire.
