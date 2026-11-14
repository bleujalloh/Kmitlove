/**
 * Chemins Storage attendus pour une photo de profil. Le document
 * `users/{uid}/photos/{id}` est écrit par le client (firestore.rules) : son
 * champ `storagePath` ne doit donc JAMAIS être utilisé tel quel par un code
 * serveur qui lit, signe ou supprime un fichier avec les droits de l'Admin
 * SDK — sans cette vérification, un membre pouvait y mettre le chemin du
 * selfie d'un autre membre (revue indépendante du 14/11/2026).
 */
export function isProfilePhotoPath(path: unknown, ownerUid?: string): path is string {
  if (typeof path !== "string") return false;
  const match = /^profile_photos\/([^/]+)\/[^/]+$/.exec(path);
  return match !== null && (ownerUid === undefined || match[1] === ownerUid);
}
