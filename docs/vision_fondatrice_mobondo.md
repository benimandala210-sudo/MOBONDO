# Vision fondatrice de MOBONDO

> **UN MONDE. UNE VIE. TA PROPRE HISTOIRE.**

Ce document est la boussole de conception de MOBONDO. Chaque fonctionnalité, chaque quartier, chaque personnage et chaque choix technique doit renforcer cette vision. Une fonctionnalité isolée ne doit jamais détourner le projet de son identité.

## 1. Le jeu que nous construisons

MOBONDO est un jeu vidéo de simulation de vie en monde ouvert, ancré dans la réalité quotidienne de Kinshasa, en République démocratique du Congo. Le joueur incarne au départ un jeune kuluna de Mapela–Raïs, dans la commune de Masina : un jeune homme dont la réputation peut inspirer la crainte, provoquer le respect, attirer des rivaux et attirer l'attention de la police. Cette identité de départ est centrale dans le scénario et le gameplay.

MOBONDO est une simulation de vie urbaine en monde ouvert qui assume les conflits, les actes illégaux et leurs conséquences. Le joueur peut provoquer des scandales, se battre, intimider, voler des voitures ou des motos, fuir la police, être arrêté, être blessé ou mourir. Ces possibilités ne doivent toutefois pas transformer le jeu en parcours criminel obligatoire : le joueur garde la liberté de poursuivre cette vie, de changer de comportement ou de reconstruire sa réputation.

## 2. Liberté du joueur

Le joueur doit pouvoir choisir ses priorités et changer de direction à tout moment :
- chercher un emploi, travailler, apprendre un métier et progresser ;
- créer une activité, gérer un commerce, développer une entreprise ;
- louer ou acquérir un logement, aménager son espace et construire un foyer ;
- nouer des amitiés, entretenir des relations et fonder une famille ;
- se déplacer à pied, à moto, en taxi et avec les transports disponibles ;
- participer à la vie du quartier, se divertir, faire du sport, se reposer ;
- poursuivre ses ambitions personnelles, explorer et simplement vivre son quotidien.

Les missions et activités sont des possibilités, jamais une obligation permanente. Le mode libre doit rester réellement libre. La criminalité et la réputation de kuluna sont au cœur de l'identité initiale du personnage, mais elles ne doivent pas enfermer le joueur dans une seule trajectoire.

## 3. Un monde vivant et crédible

Le quartier ne doit pas être un décor vide. Il doit évoluer et réagir :
- habitants et personnages non-joueurs avec des identités, des routines, des besoins et des relations ;
- circulation, piétons, taxis, motos, transports et interactions cohérentes ;
- commerces, marchés, services publics, écoles, lieux de culte, espaces de sport et lieux de rencontre ;
- alternance jour/nuit, météo et rythme des activités ;
- économie locale avec emplois, revenus, dépenses, prix, stocks, clients et entreprises ;
- conséquences lisibles des décisions du joueur sur sa situation et ses relations ;
- réputation de quartier, peur, respect, rivalités, témoins et mémoire des incidents ;
- police avec patrouilles, suspicion, poursuites, arrestations, détention et retour dans le quartier ;
- conséquences des affrontements : blessures, perte de ressources, représailles, réputation et risque de mort.

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

## 7. Personnage principal, réputation et police

Le personnage commence comme un jeune kuluna connu dans son environnement. Sa réputation doit influencer les réactions des habitants, les comportements des rivaux, les opportunités et les risques.

Les systèmes à construire sont :
- **Crainte et réputation de rue :** notoriété, respect ou peur, rumeurs, réactions des habitants et rivalités.
- **Attention policière :** surveillance liée à la gravité et à la répétition des incidents, aux témoins, au lieu et à l'heure.
- **Historique des incidents :** scandales, intimidations, affrontements, agressions et vols de véhicules.
- **Conséquences :** poursuites, arrestation, interrogatoire, détention, amende ou perte de biens, blessures et risque de mort.

La police doit fonctionner comme un système cohérent : repérer un incident, poursuivre le joueur, éventuellement le perdre de vue, procéder à une arrestation et gérer une période de détention. Les habitants doivent réagir de façons différentes : peur, résistance, dénonciation, soutien ou vengeance. Les actes peuvent procurer un avantage immédiat, mais créent des risques crédibles.

La mort du personnage doit être une conséquence rare mais réelle, pensée avec la sauvegarde et la continuité de partie. Elle ne doit jamais être déclenchée par le seul niveau de réputation.

## 8. Règles des missions et des épisodes

Les missions scénarisées sont organisées en épisodes qui se débloquent dans l'ordre. Le joueur doit accomplir l'objectif principal d'un épisode pour débloquer le suivant. Une mission prend fin immédiatement dès que l'une des trois conditions terminales suivantes survient :

1. **Objectif principal accompli — victoire :** la mission se termine, une cinématique de victoire présente la conclusion et le bilan, puis l'épisode suivant est débloqué.
2. **Joueur arrêté par la police — échec :** la mission s'arrête immédiatement. Une cinématique de défaite est jouée, puis le joueur recommence l'épisode échoué.
3. **Joueur tué — échec :** la mission s'arrête immédiatement. Une cinématique de défaite est jouée, puis l'épisode recommence depuis l'état sauvegardé au début de cet épisode.

Les objectifs secondaires sont facultatifs : les manquer ne transforme pas une victoire principale en échec et ne bloque pas le déblocage de l'épisode suivant ; cela réduit seulement la récompense obtenue. Chaque issue, victoire comme défaite, doit avoir une conclusion cinématographique et un bilan cohérent. Une arrestation ou la mort du personnage ne permet jamais de poursuivre la mission en cours.

Les missions peuvent être jouées en solo ou en équipe lorsque le scénario le prévoit. Ces épisodes scénarisés doivent coexister avec le mode libre : ils ne doivent pas supprimer la liberté du joueur dans le monde ouvert.

## 9. Questions obligatoires avant toute nouvelle fonctionnalité

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


## 10. Représentation des affrontements de rue
Les affrontements du quartier doivent refléter les éléments signalés lors de la conception terrain : machettes, pierres et lames de type Gillette peuvent apparaître comme armes de jeu. Leur présence doit être identifiable dans les choix d'équipement et les animations, sans glorification ni représentation graphique des blessures. Les mécaniques restent abstraites et ludiques : portée, disponibilité, temps de récupération, dégâts non graphiques et conséquences sur la santé, la réputation, les témoins et l'attention policière. Cette représentation ne constitue pas un guide d'utilisation réelle des armes.

## Direction artistique — révision visuelle (13 novembre 2026)

L'identité visuelle de MOBONDO doit évoluer au-delà des volumes géométriques bruts. La cible est un **réalisme stylisé urbain**, crédible et lisible sur Android : architecture de quartier kinoise, matériaux mats et irréguliers, tôles patinées, enduits de murs, poussière, béton usé, vitrages, enseignes, mobilier et végétation variés. Les silhouettes humaines doivent progressivement recevoir des proportions, vêtements, visages et animations cohérents.

Les primitives restent autorisées pour les collisions, prototypes et éléments secondaires, mais ne doivent plus être la finition dominante des bâtiments, véhicules ou personnages. Les matériaux procéduraux légers peuvent apporter une première variation de surface ; ils ne remplacent pas les textures photographiques optimisées, les modèles 3D travaillés ni les animations de qualité.

**Priorité technique :** stabiliser l'épisode 1, puis remplacer les éléments les plus visibles par des assets optimisés, avec niveaux de détail, limitation des ombres dynamiques, regroupement des surfaces statiques et budget mémoire adapté aux téléphones Android modestes. Toute amélioration visuelle doit être mesurée sur appareil réel ; aucune qualité graphique ne justifie des plantages.

