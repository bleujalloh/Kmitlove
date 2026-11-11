// `Intl.supportedValuesOf` existe réellement dans le runtime Node 22 des
// Cloud Functions (functions/package.json "engines") depuis Node 18,
// mais la cible TypeScript du projet reste es2020 (tsconfig.json) dont
// les types ne le déclarent pas encore — déclaration ambiante minimale
// plutôt que relever la cible de compilation de tout le projet pour une
// seule méthode.
declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Intl {
    function supportedValuesOf(key: string): string[];
  }
}

const KNOWN_TIME_ZONES = new Set(Intl.supportedValuesOf("timeZone"));

/**
 * Vérifie qu'une chaîne est un identifiant IANA réellement connu du
 * moteur (ex. "Europe/Paris") — jamais une confiance aveugle au client
 * (règlement permanent section 6), qui pourrait envoyer n'importe quelle
 * chaîne arbitraire.
 */
export function isValidTimeZone(timezone: string): boolean {
  return KNOWN_TIME_ZONES.has(timezone);
}

// Ancrée en fin de chaîne (pas seulement en préfixe) : une chaîne qui
// porte déjà un "Z" ou un décalage explicite (+02:00...) ne doit jamais
// être acceptée silencieusement et réinterprétée une seconde fois comme
// une heure murale naïve — trouvé par revue de code, c'est exactement ce
// qui aurait laissé passer sans erreur une chaîne déjà absolue.
const NAIVE_DATE_TIME_PATTERN = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.(\d{1,3}))?$/;

const formatterCache = new Map<string, Intl.DateTimeFormat>();

function formatterFor(timezone: string): Intl.DateTimeFormat {
  let formatter = formatterCache.get(timezone);
  if (!formatter) {
    formatter = new Intl.DateTimeFormat("en-US", {
      timeZone: timezone,
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
      second: "2-digit",
      hourCycle: "h23",
    });
    formatterCache.set(timezone, formatter);
  }
  return formatter;
}

/**
 * Convertit une date-heure "naïve" (chaîne ISO SANS décalage, telle
 * qu'écrite par le client — create_post_screen.dart n'appelle jamais
 * `.toUtc()`) en véritable instant UTC, en l'interprétant comme une
 * heure murale dans le fuseau IANA fourni (celui de l'organisateur au
 * moment de la création — createCommunityPost.ts).
 *
 * Deux passes, l'algorithme standard pour ce problème (le même que des
 * bibliothèques comme date-fns-tz en interne, réécrit ici avec
 * uniquement `Intl`, déjà disponible dans le runtime Node des Cloud
 * Functions, pour éviter une dépendance supplémentaire) : la première
 * passe approche l'instant en supposant un décalage nul, la seconde
 * corrige le résidu dû à un éventuel changement d'heure (heure
 * d'été/d'hiver) autour de cet instant précis. Limite acceptée et non
 * corrigée : une heure murale qui n'existe pas du tout (l'heure "sautée"
 * au changement d'heure d'été, une seule heure par an par fuseau
 * concerné) n'a par nature aucune interprétation unique correcte — même
 * les bibliothèques dédiées font un choix arbitraire dans ce cas précis.
 */
export function zonedWallTimeToUtcMillis(naiveIso: string, timezone: string): number {
  const match = NAIVE_DATE_TIME_PATTERN.exec(naiveIso);
  if (!match) {
    throw new Error(`Date invalide (attendu une heure naïve, sans décalage) : ${naiveIso}`);
  }
  const [, year, month, day, hour, minute, second, ms] = match;
  const targetAsUtcMillis = Date.UTC(
    Number(year),
    Number(month) - 1,
    Number(day),
    Number(hour),
    Number(minute),
    Number(second),
    ms ? Number(ms.padEnd(3, "0")) : 0,
  );

  const formatter = formatterFor(timezone);

  function wallClockAsUtcMillis(instantMillis: number): number {
    const parts = formatter.formatToParts(new Date(instantMillis));
    const get = (type: string): number => Number(parts.find((p) => p.type === type)?.value ?? "0");
    return Date.UTC(get("year"), get("month") - 1, get("day"), get("hour"), get("minute"), get("second"));
  }

  let guess = targetAsUtcMillis;
  for (let i = 0; i < 2; i += 1) {
    const offset = wallClockAsUtcMillis(guess) - guess;
    guess = targetAsUtcMillis - offset;
  }
  return guess;
}
