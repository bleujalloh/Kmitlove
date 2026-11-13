import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';

import '../data/major_cities.dart';

/// Champ "pays" piloté par un vrai sélecteur (liste ISO 3166-1 complète
/// via `country_picker`, demande explicite du propriétaire le
/// 12/11/2026) — remplace un champ texte libre où n'importe quel pays
/// fictif pouvait être enregistré.
///
/// Le nom ENREGISTRÉ est toujours en français, quelle que soit la
/// locale d'affichage courante de l'app (`CountryLocalizations(Locale('fr'))`
/// construit directement, jamais `country.getTranslatedName(context)` qui
/// suit la locale ambiante) : `emergency_sheet.dart` indexe ses numéros
/// d'urgence connus par nom de pays français en dur, et plusieurs autres
/// écrans affichent `country` tel quel sans jamais le traduire — un
/// membre choisissant son pays pendant que l'app est en anglais aurait
/// sinon enregistré "Belgium" au lieu de "Belgique", cassant cette
/// recherche et affichant une incohérence partout ailleurs (trouvé par
/// revue de code). Seule la LISTE affichée dans le sélecteur suit la
/// locale de l'app (délégué `CountryLocalizations.delegate`, main.dart) ;
/// `saveProfil.ts` valide le nom retenu contre la liste fermée
/// VALID_COUNTRY_NAMES côté serveur — jamais une confiance aveugle à ce
/// que le client envoie.
/// Nom français stocké pour un pays choisi — source unique partagée par
/// CountryField et le sélecteur de la rangée de pilules Découvrir, pour
/// que le nom filtré corresponde toujours exactement à celui enregistré
/// (VALID_COUNTRY_NAMES, countryLower).
String frenchCountryName(Country country) =>
    CountryLocalizations(const Locale('fr')).countryName(countryCode: country.countryCode) ??
    country.name;

class CountryField extends StatelessWidget {
  const CountryField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
  });

  final String? value;
  final ValueChanged<String> onChanged;
  final String label;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => showCountryPicker(
        context: context,
        showPhoneCode: false,
        onSelect: (country) => onChanged(frenchCountryName(country)),
      ),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          value?.isNotEmpty == true ? value! : '',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}

/// Champ "ville" avec suggestions de villes réelles selon le pays choisi
/// (auto-complétion best-effort, demande du propriétaire le 12/11/2026)
/// — contrairement au pays, aucune base de villes exhaustive n'existe
/// pour ce projet (voir core/data/major_cities.dart pour le compromis
/// retenu et pourquoi), donc la saisie libre reste TOUJOURS possible :
/// ce champ ne bloque jamais une ville réelle absente des suggestions.
/// Aucune validation fermée côté serveur sur ce champ, volontairement.
class CityField extends StatelessWidget {
  const CityField({
    super.key,
    required this.controller,
    required this.country,
    required this.label,
    this.validator,
    this.onChanged,
  });

  final TextEditingController controller;
  final String? country;
  final String label;
  final String? Function(String?)? validator;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final suggestions = country != null
        ? majorCitiesByCountry[country] ?? const []
        : const <String>[];
    // Toujours un Autocomplete, même sans aucune suggestion (liste
    // d'options alors vide) — jamais un widget différent selon que des
    // suggestions existent ou non : changer de pays alors que le champ
    // ville a le focus aurait sinon détruit/recréé l'Element à ce
    // changement de type, perdant le focus et fermant le clavier
    // (trouvé par revue de code).
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: controller.text),
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) return suggestions;
        final query = textEditingValue.text.toLowerCase();
        return suggestions.where((c) => c.toLowerCase().contains(query));
      },
      onSelected: (selection) {
        controller.text = selection;
        onChanged?.call();
      },
      fieldViewBuilder: (context, textController, focusNode, onSubmitted) {
        // `onChanged` du TextFormField (pas `textController.addListener`,
        // trouvé par revue de code) : RawAutocomplete réutilise le même
        // contrôleur interne à chaque reconstruction tant que le widget
        // reste monté, donc un `addListener` posé ici à chaque frame
        // s'empilerait sans jamais être retiré. `controller` (celui du
        // formulaire parent, utilisé pour l'enregistrement final) doit
        // quand même refléter une saisie libre qui ne correspond à
        // aucune suggestion, pas seulement une sélection dans la liste.
        return TextFormField(
          controller: textController,
          focusNode: focusNode,
          decoration: InputDecoration(labelText: label),
          validator: validator,
          onChanged: (text) {
            controller.text = text;
            onChanged?.call();
          },
        );
      },
    );
  }
}
