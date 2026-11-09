import { initializeApp } from "firebase-admin/app";

initializeApp();

export { deleteAccount } from "./account/deleteAccount";
export { startFiltrageAttempt } from "./filtrage/startAttempt";
export { submitFiltrageAttempt } from "./filtrage/submitAttempt";
export { requestFiltrageReview } from "./filtrage/requestReview";

// Les prochaines fonctions (compatibilité, matchs, jetons, Premium,
// modération) seront ajoutées ici une par une — voir
// docs/suivi-developpement.md pour l'ordre prévu.
