# Agent A2 — Age Gate (RGPD art.8 / COPPA)

## Objectif
Ajouter une porte d'âge à l'inscription pour bloquer les < 13 ans, exigée par Apple/Google et le RGPD. **Gate minimal — pas de KYC, pas de modif des fonctionnalités de l'app.**

## Fichiers
- `lib/features/auth/signup_screen.dart` (point d'entrée création de compte)
- `lib/core/providers/auth_provider.dart` (persistance d'un flag "âge vérifié")
- Strings : `language_provider.dart` (EN/FR)

## À faire
1. Avant la création effective du compte, afficher un **sélecteur de date de naissance** (ou, au minimum, une confirmation explicite "J'ai 13 ans ou plus").
   - Recommandé : date de naissance → calcul d'âge → bloc si < 13.
2. Si < 13 : écran bloquant clair (« Cette app nécessite d'avoir au moins 13 ans »), pas de création de compte.
3. Persister un flag (ex. `age_verified` / `date_of_birth`) pour ne demander **qu'une seule fois**.
4. Localiser EN + FR.

## Notes conformité
- Seuil minimum global = **13 ans** (COPPA / Apple). En France le consentement numérique RGPD est à 15 ans, mais le gate 13+ est le standard accepté pour la v1 ; on pourra durcir plus tard.
- Ne stocker que le strict nécessaire ; si date de naissance stockée, la déclarer dans App Privacy (coord. avec A4).

## Ne PAS toucher
- Le flux d'auth OAuth lui-même (Apple/Google), au-delà d'intercaler le gate.
- Aucune fonctionnalité produit.

## Critères d'acceptation
- Un nouvel utilisateur doit passer le gate avant d'accéder à l'app.
- < 13 bloqué ; gate demandé une seule fois ; FR + EN.
- `flutter analyze` propre ; pas de régression du parcours d'inscription.
