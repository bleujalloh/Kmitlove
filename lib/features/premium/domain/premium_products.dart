/// Doit correspondre exactement aux identifiants déclarés dans Google
/// Play Console / App Store Connect et côté serveur (functions/src/config.ts).
const kPremiumSubscriptionId = 'kamalove_premium_monthly';
const kJetonPackIds = ['kamalove_jetons_5', 'kamalove_jetons_15'];

const kAllProductIds = {kPremiumSubscriptionId, ...kJetonPackIds};
