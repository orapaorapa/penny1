# Prototype Xpra 8 / Chromium / Coolify 4.7.5

> **Prototype experimental non validé en exécution.** Ne pas utiliser en production ni saisir des identifiants Pennylane tant que les tests techniques et la configuration HTTPS de confiance ne sont pas validés. Cette expérimentation n'ajoute pas d'utilisateur Pennylane et ne garantit pas la conformité au contrat Pennylane.

## Objectif

Faire fonctionner **une seule instance Chromium** et plusieurs fenêtres dans **une session Xpra unique** (`:100`). Deux PC du réseau local se connectent au même serveur Xpra 8 en mode `sharing=combine`. Le mode combine attribue une **zone distincte** à chaque client compatible ; il faut tester en pratique la séparation effective des fenêtres, des souris et des claviers.

### Resolution des postes : adaptation automatique (choix retenu)

**Aucune resolution fixe de type 1920x1080 n'est imposee.** Le client Xpra HTML5 transmet les dimensions utiles de sa fenetre de navigateur au serveur, qui essaie d'ajuster la zone virtuelle de chaque client avec `sharing=combine`. En plein ecran, la surface disponible se rapproche de la resolution de l'ecran physique ; en mode fenetre, elle est plus petite. Il est normal que l'espace utile differe d'un PC a l'autre.

Le script `start.sh` selectionne **Xdummy** et active `--resize-display=yes`. La reconfiguration exige un pilote Xdummy avec RandR 1.6 et 16 sorties et la prise en charge des coordonnees relatives par les clients. **Il faut verifier ces points au premier lancement : ce n'est pas encore valide sur votre serveur Coolify.** Si Xdummy refuse de demarrer, ou si la seconde zone n'apparait pas, interrompre les essais plutot que de considerer la resolution automatique comme fonctionnelle.

**Ce prototype ouvre uniquement `example.org` et `debian.org`**, jamais Pennylane. Il ne comprend aucun robot de clic, actualisation F5 ni mécanisme destiné à prolonger artificiellement une session.

## 1. Créer le dépôt GitHub

1. Connectez-vous sur github.com.
2. Cliquez sur **+** > **New repository**.
3. Nom : `xpra-coolify-pilote`, visibilité **Private**, puis **Create repository**.
4. Décompressez le ZIP et ouvrez le dépôt GitHub dans votre navigateur.
5. Cliquez sur **Add file** > **Upload files** ; chargez les fichiers individuels `Dockerfile`, `docker-compose.yml`, `start.sh`, `launch-chromium.sh`, `README.md` et `.gitignore` (pas le ZIP lui-même). Validez avec **Commit changes**. L'ensemble doit être à la racine du dépôt.

## 2. Autoriser Coolify à lire ce dépôt privé

1. Dans Coolify, allez à **Keys & Tokens** > **Private Keys** > **New private key** > **Generate ED25519**.
2. Ouvrez la clé créée, copiez la **Public key** uniquement.
3. Sur GitHub, ouvrez le dépôt > **Settings** > **Deploy keys** > **Add deploy key**.
4. Nom : `Coolify lecture seule`, collez la clé publique, **ne cochez pas Allow write access**, puis sauvegardez.
5. Sur le dépôt GitHub, cliquez sur **Code** > **SSH** et copiez l'URL `git@github.com:VOTRE_COMPTE/xpra-coolify-pilote.git`.

Cette méthode fonctionne même si Coolify est seulement joignable sur le réseau local. Le redéploiement automatique depuis GitHub nécessiterait une configuration supplémentaire ; pour ce prototype, utilisez le bouton **Deploy** manuellement.

## 3. Créer l'application Coolify

1. **Projects** > **New Project** (exemple : `Essai-Xpra`) > environnement `production` > **+ New**.
2. Choisissez **Private Repository (with Deploy Key)**.
3. Sélectionnez votre serveur Coolify local (souvent `localhost`).
4. Sélectionnez la clé privée créée à l'étape 2.
5. Collez l'URL SSH GitHub, branche `main`, **Build Pack : Docker Compose**.
6. Base Directory : `/`, Docker Compose Location : `/docker-compose.yml`, puis Continue / Save.
7. Dans **Environment Variables**, renseignez :
   - `SERVER_LAN_IP` = adresse IPv4 réelle du serveur Ubuntu sur le LAN, **sans** `http://` ni port ;
   - `XPRA_PASSWORD` = un mot de passe de test robuste et unique, sans le mettre dans GitHub.
8. **Domains : laisser vide**. Le port 14500 est lié uniquement à l'adresse IPv4 LAN choisie. Assurez-vous que le pare-feu n'autorise que les adresses des deux PC de test.
9. Cliquez sur **Deploy**, examinez les Deployment Logs puis les Runtime Logs.

## 4. Premier test (SANS Pennylane)

Depuis PC 1 puis PC 2, ouvrez : `https://IP_DU_SERVEUR:14500` (remplacer IP_DU_SERVEUR).

Le conteneur génère un **certificat auto-signé**. Le navigateur peut montrer une alerte de certificat : **ne pas saisir d'informations sensibles**. Ce certificat sert uniquement à un test isolé. Pour un usage opérationnel il faut un certificat reconnu par les postes (autorité interne ou nom de domaine HTTPS).

Saisissez le mot de passe Xpra défini dans Coolify. Dans les paramètres Xpra HTML5, activez **Share session / sharing** si le client le propose. Le mode `sharing=combine` nécessite un Xpra 8 récent, une configuration Xdummy compatible RandR 1.6 et des clients annonçant la prise en charge des coordonnées relatives aux moniteurs.

**À vérifier avant de conclure** :

- Ouvrez la session sur un PC en 1366x768 et un autre en 1920x1080 (ou des resolutions differentes si disponibles). Chacun a-t-il sa propre surface de travail ?
- Sur un des PC, agrandissez et retrecissez la fenetre locale, puis passez en plein ecran : la zone distante suit-elle sans perturber l'autre PC ?
- Le PC 1 et le PC 2 sont-ils simultanément connectés ?
- Les deux fenêtres Chromium sont-elles visibles, éventuellement en déplaçant l'une dans la deuxième zone ?
- Cliquer / écrire sur le PC 1 ne déplace-t-il pas le focus ou le texte du PC 2 ?
- Les deux PC retrouvent-ils les fenêtres après fermeture de l'onglet local et reconnexion ?
- Après redémarrage du conteneur, le volume `chrome_pilote` garde-t-il le profil et les préférences ?

**L'adaptation automatique de l'affichage ne prouve pas l'independance des souris ou des claviers.** Ce sont deux tests differents. L'interface web Xpra rapporte la taille utile du navigateur, pas necessairement la resolution physique complete de Windows lorsque le navigateur n'est pas maximise.

**Important** : les deux fenêtres peuvent apparaître initialement dans la zone du PC 1. C'est un prototype destiné à vérifier l'attribution des zones, pas une répartition automatique terminée. Si `combine` se rabat sur `sharing=yes`, ou si le clavier/focus est partagé, le prototype ne satisfait pas l'indépendance attendue. Il faudra alors changer de conception plutôt que de déclarer le test réussi.

## 5. Arrêt / retour arrière

Dans Coolify, utilisez **Stop** sur cette application. Les deux comptes Pennylane existants ne sont pas affectés. **Ne supprimez pas le volume** si vous souhaitez garder les paramètres du pilote. Si vous supprimez l'application et ses volumes, ces données seront perdues.

## Sources techniques

- Xpra 8, `sharing=combine` et conditions Xdummy : https://xpra-org.github.io/xpra/Subsystems/Display.html
- Xdummy : https://xpra-org.github.io/xpra/Usage/Xdummy.html
- Dépôts Xpra beta : https://xpra-org.github.io/xpra/Download/Linux.html
- Clé GitHub (Coolify) : https://coolify.io/docs/applications/sources/github/deploy-key
- Application Git Docker Compose : https://coolify.io/docs/applications/builds/docker-compose
