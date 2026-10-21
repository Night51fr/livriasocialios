# Livria Social — Application iOS Officielle (`store.livria.social`)

Application iOS native **SwiftUI / Swift 6** (iOS 18.0+ / iOS 26.0+) connectée en temps réel à **`https://livriasocial.viplenetwork.com/api/mobile/v1`** et unifiée avec le compte **Viple Live ID** de **Livria Store**.

## Informations Bundle & Signature Apple
- **Nom de l'application** : `Livria Social`
- **Bundle Identifier** : `store.livria.social`
- **Organisation** : `Viple`
- **Orientations iPad Multitasking** : Toutes les 4 orientations (`Portrait`, `PortraitUpsideDown`, `LandscapeLeft`, `LandscapeRight`) configurées dans `Info.plist` et `LivriaSocial.xcodeproj/project.pbxproj`.
- **Icône d'application** : `Assets.xcassets/AppIcon.appiconset/AppIcon.png` (`1024x1024` RGB 24-bit sans canal alpha).

## Fonctionnalités Incluses
1. **Fil d'Actualité Littéraire (`FeedView`)** :
   - Publications texte, photos, vidéos, partage d'un livre du catalogue Livria Store ou partage d'une liste rémunérée.
   - Filtres temps réel (`Tout le fil`, `Avis & Livres`, `Listes (€)`, `Photos & Vidéos`).
   - 4 réactions interactives (`❤️ J'adore`, `🔥 Pépite`, `💡 Inspirant`, `👏 Bravo`) et commentaires en direct (+5 XP).
2. **Listes de Livres Rémunérées (`BookListsView`)** :
   - Création de listes thématiques à partir du catalogue officiel Livria Store (+25 XP).
   - Rémunération de **0,50 € à 1,00 € par achat** généré via la liste.
   - Ajout de livres, partage direct sur `my.livria.store/listes/{id}` et dans le fil d'actualité.
3. **Messagerie Instantanée Riche (`MessagesView` & `ConversationThreadView`)** :
   - Recherche de membres par pseudo ou `@handle` pour démarrer une discussion privée réelle.
   - Envoi de texte, photos, notes vocales, GIFs, fiches livres Livria Store et liens web.
4. **Espace Jeux de Livria (`SocialGamesHubView`)** :
   - **Bonus Quotidien & Série de jours** (+XP progressifs).
   - **Roue de la Fortune Littéraire** (1 lancer gratuit/jour : XP ou bonus en euros crédités sur la cagnotte affiliée).
   - **Quiz Culture & Littérature** (+XP selon le score).
   - **Mot Mystère Littéraire** (+25 XP par mot trouvé).
5. **Mon Profil & Studio de Personnalisation (`SocialProfileView` & `MemberPublicProfileView`)** :
   - Studio d'arrière-plan complet : **12 thèmes dégradés** ou **image de fond personnalisée**, couleur d'accentuation, opacité des cartes verre, titre/badge personnalisé, devise et biographie.
   - Authentification unifiée **Viple Live ID** partagée avec `Livria Store`.
