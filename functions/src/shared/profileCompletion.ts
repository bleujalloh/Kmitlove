/** Les champs facultatifs qui comptent pour le pourcentage de complétion
 * — seule source de vérité, utilisée à la fois par getProfileCompletion.ts
 * (affichage sur l'onglet Profil) et getDiscoverCandidates.ts (classement) :
 * ces deux usages ne doivent jamais pouvoir diverger silencieusement.
 * Jamais les champs obligatoires (toujours remplis dès que le profil
 * existe, voir saveProfil.ts) : ça resterait toujours à 100% sinon.
 */
export interface ProfilCompletionFields {
  profession?: string | null;
  languages?: string[];
  interests?: string[];
  culturalOrigins?: string[];
  heightCm?: number | null;
  educationLevel?: string | null;
  smokingHabit?: string | null;
  drinkingHabit?: string | null;
  childrenStatus?: string | null;
  lookingFor?: string | null;
  qualities?: string[];
}

const MIN_PHOTOS_FOR_FULL_COMPLETION = 3;

export function computeProfileCompletionPercent(
  profil: ProfilCompletionFields,
  approvedPhotoCount: number,
  isVerified: boolean,
): number {
  const checks = [
    Boolean(profil.profession),
    (profil.languages?.length ?? 0) > 0,
    (profil.interests?.length ?? 0) > 0,
    (profil.culturalOrigins?.length ?? 0) > 0,
    profil.heightCm !== null && profil.heightCm !== undefined,
    Boolean(profil.educationLevel),
    Boolean(profil.smokingHabit),
    Boolean(profil.drinkingHabit),
    Boolean(profil.childrenStatus),
    Boolean(profil.lookingFor),
    (profil.qualities?.length ?? 0) > 0,
    approvedPhotoCount >= MIN_PHOTOS_FOR_FULL_COMPLETION,
    isVerified,
  ];
  const filled = checks.filter(Boolean).length;
  return Math.round((filled / checks.length) * 100);
}
