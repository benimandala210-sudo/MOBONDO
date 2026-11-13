# Réactions des habitants aux affrontements

## Fonctionnalités ajoutées

Lorsqu'une attaque du joueur contre un rival réussit, les piétons visibles situés dans un rayon de 14 mètres réagissent selon leur rôle :

- Les enfants, passants et vendeurs prennent la fuite pendant quelques secondes.
- Certains habitants restent sur place et observent l'affrontement.
- D'autres habitants adoptent un comportement de signalement à la PNC.
- Les piétons qui fuient se déplacent réellement dans le quartier, puis reprennent une trajectoire de promenade adaptée à leur nouvelle position.
- Les routines ordinaires ne réinitialisent pas un personnage pendant sa réaction.

L'affrontement est enregistré une seule fois par fenêtre de dix secondes afin d'éviter de multiplier artificiellement la réputation et la pression policière à chaque coup. La présence d'au moins un témoin est prise en compte dans l'enregistrement de l'incident. Le signalement visible d'un habitant s'accompagne d'un message d'alerte ; la pression policière alimente ensuite le système PNC déjà intégré.

## Limites connues

- Les réactions reposent actuellement sur le rôle et l'index des personnages, pas sur une personnalité persistante ni sur des relations individuelles.
- Le signalement est représenté par un état et un message ; il n'y a pas encore d'animation de téléphone, de dialogue d'appel ou de délai de transmission radio.
- Les habitants ne mémorisent pas encore durablement l'identité du joueur comme témoin d'un incident.
- Les réactions et leurs déplacements restent à valider dans Godot et sur Android.

Cette tranche conserve les affrontements non graphiques et leurs conséquences. Elle ne modifie pas les trois issues terminales des missions.
