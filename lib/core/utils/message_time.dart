import 'package:intl/intl.dart';

/// Heure affichée à droite d'une conversation (prototype Messages :
/// « 14:02 », « hier », « lun. »...). Même jour : l'heure ; la veille :
/// `yesterdayLabel` (texte traduit fourni par l'appelant) ; moins d'une
/// semaine : le jour de la semaine abrégé ; au-delà : jour et mois.
/// Les dates sont comparées en heure locale de l'appareil.
String formatMessageTime(
  DateTime at,
  DateTime now, {
  required String locale,
  required String yesterdayLabel,
}) {
  final local = at.toLocal();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  final daysAgo = today.difference(day).inDays;
  if (daysAgo <= 0) return DateFormat.Hm(locale).format(local);
  if (daysAgo == 1) return yesterdayLabel;
  if (daysAgo < 7) return DateFormat.E(locale).format(local);
  return DateFormat.Md(locale).format(local);
}
