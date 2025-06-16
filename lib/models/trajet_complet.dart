import 'trajet.dart';

class TrajetComplet {
  final List<Trajet> segments;

  TrajetComplet(this.segments);

  int get correspondances => segments.length - 1;

  String get resume => segments.map((s) => s.ligne).join(" > ");
}
