# Vol de véhicules — première tranche MOBONDO

## Véhicule concerné
Une moto fictive est stationnée en bordure de la voie de Mapela. Elle est distincte de la moto de départ du joueur et des véhicules de transport public en circulation.

## Interaction
- Le joueur doit être à pied et se trouver à environ 3,2 mètres ou moins de la moto.
- Le bouton d'action mobile affiche « TENTER VOL MOTO ».
- L'action remplace le véhicule actuellement pilotable par une nouvelle moto jouable positionnée à l'emplacement de la moto ciblée.
- Le joueur monte automatiquement après le vol.
- La moto volée reste le véhicule pilotable lors de la sauvegarde de la position et du carburant.
- Le véhicule public et les taxis gardent leur interaction de transport prioritaire lorsqu'ils sont à portée.

## Témoins et PNC
- Les piétons visibles à 12 mètres ou moins comptent comme témoins.
- Le vol est enregistré via l'incident « vehicle_theft » dans le gestionnaire de réputation.
- L'incident augmente la réputation de rue et la pression policière ; les gains de pression sont réduits en l'absence de témoin.
- En mode histoire, l'alerte obtenue peut déclencher les patrouilles PNC déjà intégrées.

## Limites
- Cette tranche met en place le vol d'une moto stationnée. Le vol de voitures nécessite encore un contrôleur automobile et ses propres commandes/physique.
- Pas encore de serrure, de mini-jeu de démarrage, d'alarme sonore, de propriétaire qui poursuit le joueur, ni de système de plaques.
- Les témoins sont actuellement détectés par proximité ; ils ne passent pas encore un appel à la police.
- Aucun test de compilation Godot ni test Android n'a encore été exécuté pour cette modification.
