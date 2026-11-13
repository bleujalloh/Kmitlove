import 'dart:math' as math;

/// Distance à vol d'oiseau en kilomètres entre deux points (formule de
/// haversine). Même formule que functions/src/shared/distance.ts : utilisée
/// côté appli uniquement pour l'affichage/le filtre APPROXIMATIF des
/// événements (centre de ville), jamais pour une règle métier.
double haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const earthRadiusKm = 6371.0;
  double rad(double deg) => deg * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLon = rad(lon2 - lon1);
  final a = math.pow(math.sin(dLat / 2), 2) +
      math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.pow(math.sin(dLon / 2), 2);
  return 2 * earthRadiusKm * math.asin(math.min(1, math.sqrt(a)));
}
