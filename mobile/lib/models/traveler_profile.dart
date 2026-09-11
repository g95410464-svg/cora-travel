class TravelerProfile {
  final String id, name, country, language, budget;
  final List<String> interests;
  const TravelerProfile(
      {required this.id,
      required this.name,
      required this.country,
      required this.language,
      required this.budget,
      required this.interests});

  Map<String, Object> toJson() => {
        'id': id,
        'name': name,
        'country': country,
        'language': language,
        'budget': budget,
        'interests': interests
      };
  Map<String, Object> toContext() => {
        'nombre': name,
        'pais': country,
        'idioma': language,
        'presupuesto_diario_usd': budget,
        'intereses': interests.join(', ')
      };
  factory TravelerProfile.fromJson(Map<String, dynamic> json) =>
      TravelerProfile(
          id: json['id'] as String,
          name: json['name'] as String,
          country: json['country'] as String,
          language: json['language'] as String,
          budget: json['budget'] as String,
          interests: List<String>.from(json['interests'] as List));
}
