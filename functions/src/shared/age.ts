/** Calcule un âge en années à partir d'une date de naissance ISO. Partagé
 * entre toutes les fonctions qui en ont besoin pour éviter que deux
 * copies divergent silencieusement (ex. gestion des années bissextiles).
 */
export function computeAge(birthDateIso: string): number {
  const birth = new Date(birthDateIso);
  const now = new Date();
  let age = now.getFullYear() - birth.getFullYear();
  if (
    now.getMonth() < birth.getMonth() ||
    (now.getMonth() === birth.getMonth() && now.getDate() < birth.getDate())
  ) {
    age -= 1;
  }
  return age;
}
