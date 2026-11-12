/// Suggestions de villes RÉELLES par pays pour l'auto-complétion du champ
/// ville (demande du propriétaire le 12/11/2026) — volontairement
/// PARTIEL, pas une base de données exhaustive type GeoNames (aucune
/// n'existe encore dans ce projet, et en embarquer une ou appeler une
/// vraie API de géocodage sont deux options écartées comme
/// disproportionnées pour ce besoin : nouvelle dépendance/clé
/// API/coût, ou plusieurs centaines de milliers de lignes à maintenir).
/// Chaque ville listée ici est réelle (capitale ou grande ville connue),
/// jamais inventée — mais la couverture reste limitée aux principaux
/// pays de la communauté kamite/diaspora visée par l'app. La saisie
/// libre reste TOUJOURS possible en dehors de ces suggestions (voir
/// CityField, core/widgets/country_field.dart) : aucune validation
/// fermée côté serveur sur ce champ, contrairement au pays.
///
/// Les clés correspondent exactement aux noms français renvoyés par le
/// sélecteur de pays (country_picker, package:country_picker/strings/fr.dart)
/// — un nom qui ne correspond pas exactement ne déclenchera simplement
/// aucune suggestion, sans casser la saisie libre.
const Map<String, List<String>> majorCitiesByCountry = {
  'France': [
    'Paris',
    'Marseille',
    'Lyon',
    'Toulouse',
    'Nice',
    'Nantes',
    'Strasbourg',
    'Montpellier',
    'Bordeaux',
    'Lille',
  ],
  'Belgique': ['Bruxelles', 'Anvers', 'Gand', 'Charleroi', 'Liège'],
  'Suisse': ['Genève', 'Zurich', 'Lausanne', 'Bâle', 'Berne'],
  'Canada': ['Montréal', 'Toronto', 'Québec', 'Ottawa', 'Vancouver'],
  "États-Unis d'Amérique": [
    'New York',
    'Los Angeles',
    'Chicago',
    'Atlanta',
    'Houston',
    'Miami',
    'Washington',
  ],
  'Royaume-Uni': ['Londres', 'Manchester', 'Birmingham', 'Liverpool'],
  'Sénégal': ['Dakar', 'Thiès', 'Saint-Louis', 'Touba', 'Rufisque'],
  'Mali': ['Bamako', 'Sikasso', 'Mopti', 'Ségou'],
  "Côte d'Ivoire": ['Abidjan', 'Bouaké', 'Yamoussoukro', 'San-Pédro'],
  'Guinée': ['Conakry', 'Kankan', 'Kindia', 'Labé'],
  'Cameroun': ['Douala', 'Yaoundé', 'Garoua', 'Bafoussam'],
  'République démocratique du Congo': [
    'Kinshasa',
    'Lubumbashi',
    'Goma',
    'Kisangani',
  ],
  'République du Congo': ['Brazzaville', 'Pointe-Noire'],
  'Nigeria': ['Lagos', 'Abuja', 'Kano', 'Ibadan'],
  'Ghana': ['Accra', 'Kumasi', 'Tamale'],
  'Bénin': ['Cotonou', 'Porto-Novo', 'Parakou'],
  'Togo': ['Lomé', 'Sokodé'],
  'Burkina Faso': ['Ouagadougou', 'Bobo-Dioulasso'],
  'Haïti': ['Port-au-Prince', 'Cap-Haïtien'],
  'Maroc': ['Casablanca', 'Rabat', 'Marrakech', 'Fès'],
  'Algérie': ['Alger', 'Oran', 'Constantine'],
  'Tunisie': ['Tunis', 'Sfax', 'Sousse'],
  'Éthiopie': ['Addis-Abeba'],
  'Kenya': ['Nairobi', 'Mombasa'],
  'Afrique du Sud': ['Johannesburg', 'Le Cap', 'Pretoria', 'Durban'],
  'Brésil': ['São Paulo', 'Rio de Janeiro', 'Salvador', 'Brasília'],
  'Gabon': ['Libreville'],
  'République centrafricaine': ['Bangui'],
  'Tchad': ["N'Djamena"],
  'Niger': ['Niamey'],
  'Rwanda': ['Kigali'],
  'Burundi': ['Bujumbura'],
};
