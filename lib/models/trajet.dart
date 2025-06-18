class Trajet {
  final String ligne;
  final String depart;
  final String arrivee;
  final String position;
  final String? intermediaire;

  Trajet({
    required this.ligne,
    required this.depart,
    required this.arrivee,
    required this.position,
    this.intermediaire,
  });

  factory Trajet.fromJson(Map<String, dynamic> json) {
    return Trajet(
      ligne: json['line_name'] ?? '',
      depart: json['from_name'] ?? '',
      arrivee: json['to_name'] ?? '',
      position: json['position_average'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'line_name': ligne,
      'from_name': depart,
      'to_name': arrivee,
      'position_average': position,
    };
  }
}
