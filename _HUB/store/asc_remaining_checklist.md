# App Store Connect — tout ce qui reste à remplir (chemin + contenu)

App : **The WakeApp** · App ID **6760942950** · bundle `com.wakeapp.ceoos`
Point d'entrée : appstoreconnect.apple.com → **Mes apps → The WakeApp**

Légende : ✅ déjà fait · ⬜ à faire · ⏳ bloqué par le changement de nom Apple (Indy François)

---

## 1. Informations sur l'app  (menu gauche → Général → « Informations sur l'app »)
S'applique à toutes les versions/plateformes.

- ⬜ **Sous-titre** (localisation Anglais EU) → court accroche, 30 car. max. *(copie : `_HUB/store/listing_copy.md`)*
- ⬜ **Catégorie principale** → choisir (reco : **Productivité**) · Catégorie secondaire facultative (ex. Style de vie / Santé & remise en forme).
- ⬜ **Droits relatifs au contenu** → cliquer « Configurer » → déclarer que l'app **ne contient pas** de contenu tiers sous droits (cas standard).
- ⬜ **Classification par âge** → « Modifier » → repasser le questionnaire honnêtement (aucune violence/contenu mature → atterrit en **4+**, ce qui est OK ; le seuil 13 ans est géré par l'age gate in-app, pas ici).
- ✅ Contrat de licence = EULA standard Apple (déjà bon).

## 2. Confidentialité de l'app  (menu gauche → App Store → Confiance et sécurité → « Confidentialité de l'app »)
- ⬜ **URL de la politique de confidentialité** → `https://the-wakeapp.com/privacy`
- ✅ **Collecte de données** (8 types déclarés) — fait. Vérifier que c'est **Publié** (bouton « Publier » en haut si encore en brouillon).

## 3. Accessibilité de l'app  (même section)
- ⬜ **Ne rien remplir** (optionnel) → laisser tel quel pour la v1.

## 4. Tarifs et disponibilité  (menu gauche → « Tarifs et disponibilité »)
- ⬜ **Prix de l'app** → **Gratuit** (palier 0). L'app est gratuite, le premium est un abonnement.
- ⬜ **Disponibilité** → **Tous les pays/régions** (monde entier).

## 5. La page de version  (en haut : « App iOS 1.0 — À finaliser avant soumission »)
- ⬜ **Aperçus et captures d'écran** → onglet **iPhone** : ajouter les screenshots aux **bonnes tailles** (6,5" et 6,9"). *(quoi cadrer : `_HUB/store/screenshots_checklist.md`)* — seuls iPhone requis (pas d'iPad).
- ⬜ **Texte promotionnel** (facultatif) → court, modifiable sans review.
- ⬜ **Description** → copier depuis `_HUB/store/listing_copy.md`.
- ⬜ **Mots-clés** → copier depuis `_HUB/store/listing_copy.md` (100 car., séparés par des virgules, sans espaces).
- ⬜ **URL de support** → une page de contact/support (ex. `https://the-wakeapp.com/support` ou un mailto). Obligatoire.
- ⬜ **URL marketing** (facultatif) → `https://the-wakeapp.com`.
- ⬜ **Build** → sélectionner le build uploadé via Xcode (section « Build » de la page de version). *(Il faut donc d'abord uploader un build d'archive depuis Xcode → Product → Archive → Distribute.)*
- ⬜ **Conformité au chiffrement (Export Compliance)** → si demandé : « Non / chiffrement standard exempté » (la clé `ITSAppUsesNonExemptEncryption=false` est déjà dans Info.plist).
- ⬜ **Achats intégrés et abonnements** (sur la page de version) → **sélectionner les 2 abonnements** à soumettre AVEC cette version (le 1er abonnement DOIT être soumis avec le build).
- ⬜ **Informations pour la vérification (App Review)** → coordonnées + **compte de démo** (email + mot de passe d'un compte test) + **notes** (copie : `_HUB/store/review_notes.md`, inclut l'explication « Screen Time = on-device »).

## 6. Abonnements  (menu gauche → Monétisation → « Abonnements »)
- ✅ Groupe « WakeApp Pro » localisé + métadonnées des 2 abonnements — fait.
- ⬜ **Prix mensuel** = **2,99 €** (com.wakeapp.pro.monthly) — vérifier qu'il est bien posé.
- ⬜ **Prix annuel** (com.wakeapp.pro.yearly) → **fixer** (reco **19,99 €/an**).
- ⬜ **Capture de revue** sur **chaque** abonnement (la version 1242×2688 est prête sur le Bureau — l'uploader aussi sur le Monthly).
- ⬜ **App-Specific Shared Secret** → (menu Abonnements → « App-Specific Shared Secret » / ou App Information) **générer** → **coller dans RevenueCat** (résout « Could not check » / « Missing Metadata »). *(Faisable maintenant, n'attend pas le contrat.)*
- ⬜ État des 2 abonnements doit passer à **« Prêt à soumettre »**.

## 7. Accords, taxes et banque  (barre du haut → **Business** ; niveau compte, pas par-app)  ⏳
- ⬜ **Accepter le contrat de licence Apple Developer mis à jour** (titulaire).
- ⏳ **Contrat « Apps payantes »** → s'active une fois : **nom légal corrigé (Indy François)** + **formulaires fiscaux** (W-8BEN au bon nom) + **banque** (Revolut) traités.
- ⬜ **Formulaires fiscaux** (W-8BEN + Certificate of Foreign Status) → remplir **au nom corrigé** (cf. guide W-8BEN qu'on a fait).

---

## Ordre conseillé
1. **Maintenant** : §1, §2 (URL privacy une fois le site publié ce soir), §4, §5 (sauf le build si pas encore uploadé), §6 prix annuel + Shared Secret.
2. **Build** : archiver depuis Xcode + uploader → le sélectionner en §5.
3. **Après nom Apple corrigé** : §7 (contrat/taxes/banque) → contrat Apps payantes Actif → abonnements « Prêts à la vente ».
4. **Soumettre** la version + les abonnements ensemble.

## Bloquants durs avant le bouton « Soumettre »
- URL privacy renseignée · screenshots ajoutés · description/mots-clés/sous-titre · catégorie · classification d'âge · build sélectionné · compte de démo + notes de review · les 2 abonnements « Prêts à soumettre » et sélectionnés sur la version · contrat Apps payantes **Actif** (sinon les abonnements ne partent pas).
