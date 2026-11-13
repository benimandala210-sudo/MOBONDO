# Mémoire sociale et peur persistante des habitants

## Ce qui est implémenté

Le gestionnaire de dialogues conserve maintenant une mémoire sociale individuelle pour les personnages avec lesquels le joueur peut parler.

Pour chaque habitant témoin :
- le niveau de peur augmente après un affrontement ou un vol de véhicule ;
- l'hostilité augmente également ;
- le nombre d'incidents et le dernier type d'incident sont mémorisés ;
- les valeurs sont sauvegardées dans le fichier de dialogue local et rechargées à la reprise.

Les témoins sont enregistrés dans les rayons de détection déjà utilisés par les réactions de foule. Un délai de dix secondes par personnage empêche de compter chaque coup comme un nouvel incident social.

## Conséquences visibles

- À partir d'un certain niveau de peur, l'habitant s'écarte physiquement du joueur lorsqu'il s'approche.
- Un habitant très effrayé refuse l'interaction et demande au joueur de le laisser tranquille.
- Un habitant moins effrayé mais marqué par les incidents ouvre le dialogue avec une réaction prudente ou hostile.
- La mémoire sociale a priorité sur les messages génériques liés à la réputation globale : deux habitants peuvent donc réagir différemment au même joueur.

## Règles et limites

- La peur et l'hostilité sont persistantes dans la sauvegarde locale ; elles ne diminuent pas encore avec le temps.
- Les témoins sont les personnages possédant un identifiant de dialogue ; les figurants sans identité sociale ne conservent pas encore de mémoire individuelle.
- Les représailles immédiates des groupes rivaux restent gérées par le système d'affrontement existant. Une mémoire durable des rivalités entre groupes et des représailles lors des visites ultérieures reste à développer.
- Les interactions sociales sont principalement représentées par des déplacements simples, des refus et des ouvertures de dialogue ; les animations faciales et vocales restent à produire.
- Cette tranche a été vérifiée statiquement dans les fichiers source, mais n'a pas encore été compilée par Godot ni testée sur Android.

La mémoire sociale enrichit la liberté du joueur : elle rend ses actes visibles et durables sans imposer une trajectoire criminelle unique.
