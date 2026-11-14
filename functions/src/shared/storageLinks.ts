import { getStorage } from "firebase-admin/storage";

/**
 * Lien de téléchargement d'un fichier Storage pour l'Admin SDK (export des
 * données du membre, revue des selfies par un modérateur).
 *
 * 1. Le jeton de téléchargement que Firebase pose lui-même sur tout fichier
 *    envoyé depuis l'appli : c'est exactement le lien que l'appli utilise
 *    déjà pour afficher la photo à son propriétaire, et il ne demande aucune
 *    permission IAM supplémentaire.
 * 2. À défaut, une URL signée de 10 minutes (demande la permission de
 *    signature du compte de service, absente par défaut en production —
 *    constaté par le test réel du 14/11/2026, d'où le jeton en premier).
 * Renvoie `null` si aucun des deux n'est possible (l'erreur est journalisée).
 *
 * Le CHEMIN doit avoir été validé par l'appelant (shared/storagePaths.ts) :
 * ce code lit avec les droits de l'Admin SDK.
 */
export async function downloadLinkFor(storagePath: string): Promise<string | null> {
  const bucket = getStorage().bucket();
  const file = bucket.file(storagePath);
  try {
    const [metadata] = await file.getMetadata();
    const raw = metadata.metadata?.firebaseStorageDownloadTokens;
    const token = typeof raw === "string" ? raw.split(",").find((t) => t.length > 0) : undefined;
    if (token) {
      return `https://firebasestorage.googleapis.com/v0/b/${bucket.name}/o/${encodeURIComponent(storagePath)}?alt=media&token=${token}`;
    }
  } catch (err) {
    // eslint-disable-next-line no-console
    console.error("downloadLinkFor: métadonnées illisibles", { storagePath, err });
    return null;
  }
  try {
    const [url] = await file.getSignedUrl({ action: "read", expires: Date.now() + 10 * 60 * 1000 });
    return url;
  } catch (err) {
    // eslint-disable-next-line no-console
    console.error("downloadLinkFor: aucun lien possible", { storagePath, err });
    return null;
  }
}
