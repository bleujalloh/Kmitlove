import { getFirestore } from "firebase-admin/firestore";

type Db = ReturnType<typeof getFirestore>;

const CHUNK_SIZE = 500; // limite d'un lot Firestore

/** Supprime une liste de documents par lots de 500 — partagé par tout ce
 * qui nettoie beaucoup de documents d'un coup (suppression de compte,
 * tâches planifiées).
 */
export async function deleteRefsInChunks(
  db: Db,
  refs: FirebaseFirestore.DocumentReference[],
): Promise<void> {
  for (let i = 0; i < refs.length; i += CHUNK_SIZE) {
    const batch = db.batch();
    for (const ref of refs.slice(i, i + CHUNK_SIZE)) {
      batch.delete(ref);
    }
    await batch.commit();
  }
}

/** Même principe que deleteRefsInChunks, mais pour une mise à jour
 * identique appliquée à beaucoup de documents (ex. modération planifiée).
 */
export async function updateRefsInChunks(
  db: Db,
  refs: FirebaseFirestore.DocumentReference[],
  data: Record<string, unknown>,
): Promise<void> {
  for (let i = 0; i < refs.length; i += CHUNK_SIZE) {
    const batch = db.batch();
    for (const ref of refs.slice(i, i + CHUNK_SIZE)) {
      batch.update(ref, data);
    }
    await batch.commit();
  }
}
