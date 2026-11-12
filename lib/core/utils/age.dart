/// Âge en années pleines à partir d'une date de naissance — logique
/// partagée (trouvée dupliquée à l'identique dans mon_profil_screen.dart,
/// profil_edit_screen.dart et profil_wizard_screen.dart par revue de
/// code, puis une 4e fois dans profil_detail_controller.dart).
int ageFromBirthDate(DateTime birthDate) {
  final now = DateTime.now();
  var age = now.year - birthDate.year;
  if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
    age -= 1;
  }
  return age;
}
