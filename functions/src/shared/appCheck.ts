/**
 * Firebase App Check : prouve que l'appel vient de la vraie application
 * MERUT (Play Integrity sur Android) et non d'un script externe.
 *
 * Le client l'active déjà (lib/main.dart). Côté serveur, l'exigence est
 * posée sur TOUTES les fonctions appelables par cette seule constante, mais
 * reste désactivée tant que les prérequis ne sont pas faits — l'activer trop
 * tôt couperait l'accès à tous les membres :
 *   1. enregistrer l'application Android dans Firebase > App Check
 *      (fournisseur Play Integrity) et ajouter l'empreinte SHA-256 de
 *      signature de la version publiée ;
 *   2. publier une version de l'app qui envoie bien les jetons App Check ;
 *   3. contrôler dans la console App Check que la quasi-totalité des appels
 *      sont « vérifiés » (mode surveillance) ;
 *   4. seulement alors, passer cette constante à `true` et redéployer les
 *      fonctions (docs/rgpd-registre-des-traitements.md §9).
 */
export const ENFORCE_APP_CHECK = false;
