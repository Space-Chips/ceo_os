# Agent A1 — Paywall Compliance (Apple 3.1.1 / 3.1.2)

## Objectif
Rendre le paywall conforme aux règles Apple sur les abonnements auto-renouvelables. **Câblage uniquement — aucune modif de fonctionnalité, de prix, ni de logique d'achat.**

## Fichier principal
`lib/components/premium_paywall.dart` (composant `PremiumPaywallContent`)
Strings : `lib/core/providers/language_provider.dart` (et/ou `language_overrides.dart`) — EN + FR (+ ES si déjà présent).
Service déjà prêt : `lib/core/services/billing_service.dart` → `restorePurchases()` (l.190), `purchasePremium()`.

## À faire (tout doit être visible AVANT l'achat, dans le paywall)
1. **Bouton "Restore Purchases" / "Restaurer les achats"**
   - Appeler `BillingService().restorePurchases()`, afficher un dialog de résultat (succès / rien à restaurer / erreur).
   - Toujours visible pour un utilisateur non-premium (placer sous le bouton d'achat).
2. **Liens fonctionnels Terms (EULA) + Privacy**
   - Les méthodes `_openTerms()` / `_openPrivacy()` existent déjà (l.240-246) mais ne sont JAMAIS rendues → ajouter une ligne de liens cliquables en bas du paywall.
3. **Texte d'auto-renouvellement** (obligatoire 3.1.2), EN + FR, ex. :
   - FR : « L'abonnement est facturé via ton compte $store. Il se renouvelle automatiquement au même tarif sauf annulation au moins 24 h avant la fin de la période en cours. Gérable et résiliable dans les réglages de ton compte. »
   - EN : « Billed via your $store account. Auto-renews at the same price unless cancelled at least 24h before the end of the current period. Manage or cancel anytime in your account settings. »
4. Vérifier que **titre + durée + prix (priceLabel/durationLabel)** restent affichés (déjà le cas via `_HeroPricePill` / `_PackageOptionCard`).

## Ne PAS toucher
- La logique de prix, les offerings RevenueCat, le gating `paywallEnabled`, les bénéfices listés.
- Aucun autre écran.

## Critères d'acceptation
- Paywall affiche : titre + durée + prix + bénéfices + **Restore** + **liens Terms/Privacy fonctionnels** + **texte auto-renew**, en FR et EN.
- `flutter analyze` propre sur le fichier modifié.
- Le flux d'achat existant fonctionne toujours à l'identique.

## Entrée requise
- Confirmer le nom commercial affiché : le paywall dit **"WakeApp Premium"** alors que l'app s'appelle **CEO OS** → décision hub à trancher avant (voir _HUB).
