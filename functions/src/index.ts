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
export { useJetonToResurface } from "./premium/useJeton";
export { activateBoost } from "./premium/activateBoost";
export { adminListModerationRequests, adminResolveModerationRequest } from "./admin/moderationRequests";
export { resolveFiltrageReview } from "./admin/resolveFiltrageReview";
export { adminListPendingCommunityPosts, adminReviewCommunityPost } from "./admin/reviewCommunityPost";
export { autoApprovePhotos } from "./photos/autoApprovePhotos";
export { adminListPendingPhotos, adminReviewPhoto } from "./photos/adminReviewPhoto";
export { submitIdentityVerification } from "./identite/submitIdentityVerification";
export {
  adminListIdentityVerifications,
  adminReviewIdentityVerification,
} from "./identite/adminReviewIdentity";
export { bootstrapFirstAdmin } from "./admin/bootstrapFirstAdmin";
export { recordActivity } from "./account/recordActivity";
export { registerDeviceSignal } from "./account/registerDeviceSignal";
export { expireMatches } from "./scheduled/expireMatches";
export { exportMyData } from "./rgpd/exportMyData";
export { updateMyLocation } from "./account/updateMyLocation";
export { adminListUsers, adminSetSuspension } from "./admin/listUsers";
export { adminSeedQuestionBanks } from "./admin/seedQuestionBanks";
export { adminListActionLogs } from "./admin/listActionLogs";
export { requestSanctionAppeal } from "./account/requestSanctionAppeal";
export { resolveSanctionAppeal } from "./admin/resolveSanctionAppeal";
export { triggerEmergencyAlert } from "./securite/triggerEmergencyAlert";
export { liftExpiredSuspensions } from "./scheduled/liftExpiredSuspensions";

// Paiements (Google Play, Stripe, PayPal) : travail mis en pause sur
// demande explicite, le temps de valider la conformité des règles Google
// Play sur la facturation alternative en zone EEE — ne pas redéployer ces
// fonctions avant nouvelle instruction, même si leur code est prêt.
// export { verifyPurchase } from "./premium/verifyPurchase";
// export { playRtdn } from "./paiements/playRtdn";
// export { createStripeCheckoutSession, stripeWebhook } from "./paiements/stripe";
// export { createPaypalOrder, capturePaypalOrder } from "./paiements/paypal";

// Les prochaines fonctions (compatibilité, matchs, jetons, Premium,
// modération) seront ajoutées ici une par une — voir
// docs/suivi-developpement.md pour l'ordre prévu.
