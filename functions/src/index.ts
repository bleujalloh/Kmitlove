import { initializeApp } from "firebase-admin/app";

initializeApp();

export { deleteAccount } from "./account/deleteAccount";
export { startFiltrageAttempt } from "./filtrage/startAttempt";
export { submitFiltrageAttempt } from "./filtrage/submitAttempt";
export { requestFiltrageReview } from "./filtrage/requestReview";
export { computeCompatibility } from "./compatibilite/computeCompatibility";
export { getDiscoverCandidates } from "./decouvrir/getCandidates";
export { recordSwipe } from "./decouvrir/recordSwipe";
export { getLikes } from "./likes/getLikes";
export { retractLike } from "./likes/retractLike";
export { onMessageCreated } from "./messagerie/onMessageCreated";
export { reportUser } from "./messagerie/reportUser";
export { createCommunityPost } from "./communaute/createCommunityPost";
export { requestParticipation, respondToParticipation, checkInParticipant } from "./communaute/participation";
export { getEventLocation } from "./communaute/getEventLocation";
export { reportCommunityPost } from "./communaute/reportCommunityPost";

// Les prochaines fonctions (compatibilité, matchs, jetons, Premium,
// modération) seront ajoutées ici une par une — voir
// docs/suivi-developpement.md pour l'ordre prévu.
