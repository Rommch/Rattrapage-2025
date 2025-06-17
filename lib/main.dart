import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/trajet.dart';

void main() => runApp(MonAppli());

class MonAppli extends StatelessWidget {
  const MonAppli({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trajets RATP',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: PageAccueil(),
    );
  }
}

class PageAccueil extends StatefulWidget {
  const PageAccueil({super.key});

  @override
  State<PageAccueil> createState() => _PageAccueilState();
}

class _PageAccueilState extends State<PageAccueil> {
  String? stationDepart;
  String? stationArrivee;

  List<Trajet> trajets = [];
  List<String> toutesLesStations = [];
  List<Trajet> trajetsFiltres = [];

  Map<String, List<Map<String, String>>>? graphe;

  @override
  void initState() {
    super.initState();
    chargerDonnees();
  }

  Future<void> chargerDonnees() async {
    final contenu = await rootBundle.loadString('donnees/positionnement.json');
    final data = json.decode(contenu) as List<dynamic>;
    final trajetsList = data.map((e) => Trajet.fromJson(e)).toList();

    final Set<String> stations = {};
    for (var t in trajetsList) {
      stations.add(t.depart);
      stations.add(t.arrivee);
    }

    graphe = construireGraphe(data);

    setState(() {
      trajets = trajetsList;
      toutesLesStations = stations.toList()..sort();
    });

    final chemin = itineraire(graphe!, 'Châtelet', 'Bastille');
    print('Itinéraire Châtelet -> Bastille : $chemin');
  }

  void rechercherTrajets() {
    final trajetsDirecs = trajets.where((t) =>
      t.depart == stationDepart && t.arrivee == stationArrivee
    ).toList();

    if (trajetsDirecs.isEmpty) {
      rechercherAvecCorrespondance();
    } else {
      setState(() {
        trajetsFiltres = trajetsDirecs.take(5).toList();
      });
    }
  }

  void rechercherAvecCorrespondance() {
    List<List<Trajet>> resultats = [];

    for (var premier in trajets) {
      if (premier.depart != stationDepart) continue;

      for (var second in trajets) {
        if (second.arrivee != stationArrivee) continue;

        if (premier.arrivee == second.depart) {
          resultats.add([premier, second]);
        }
      }
    }

    final correspondances = resultats.take(5).toList();

    setState(() {
      trajetsFiltres = correspondances.map((pair) {
        return Trajet(
          ligne: '${pair[0].ligne} → ${pair[1].ligne}',
          depart: pair[0].depart,
          arrivee: pair[1].arrivee,
          position: 'Correspondance à ${pair[0].arrivee}',
        );
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: trajets.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    color: Color(0xFF4EE2C0),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                ),
                Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 20),
                    child: Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Text(
                              "Nouveau trajet",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: 30),
                          Text("STATION DE DÉPART", style: TextStyle(fontSize: 12, color: Colors.grey[500], letterSpacing: 1)),
                          SizedBox(height: 6),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Color(0xFF4EE2C0)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Icon(Icons.radio_button_checked, color: Colors.green),
                                ),
                                Expanded(
                                  child: Autocomplete<String>(
                                    optionsBuilder: (textEditingValue) {
                                      return toutesLesStations.where((station) =>
                                          station.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                                    },
                                    onSelected: (value) {
                                      setState(() => stationDepart = value);
                                    },
                                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                                      return TextField(
                                        controller: controller,
                                        focusNode: focusNode,
                                        decoration: InputDecoration(
                                          hintText: 'Gare',
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 18),
                          Text("STATION D'ARRIVÉE", style: TextStyle(fontSize: 12, color: Colors.grey[500], letterSpacing: 1)),
                          SizedBox(height: 6),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Color(0xFF4EE2C0)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Icon(Icons.location_on, color: Colors.pink),
                                ),
                                Expanded(
                                  child: Autocomplete<String>(
                                    optionsBuilder: (textEditingValue) {
                                      return toutesLesStations.where((station) =>
                                          station.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                                    },
                                    onSelected: (value) {
                                      setState(() => stationArrivee = value);
                                    },
                                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                                      return TextField(
                                        controller: controller,
                                        focusNode: focusNode,
                                        decoration: InputDecoration(
                                          hintText: 'République',
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 28),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF4EE2C0),
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              onPressed: (stationDepart != null && stationArrivee != null)
                                  ? () {
                                      rechercherTrajets();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => PageResultats(
                                            depart: stationDepart!,
                                            arrivee: stationArrivee!,
                                            trajets: trajetsFiltres,
                                          ),
                                        ),
                                      );
                                    }
                                  : null,
                              child: Text("Rechercher"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class PageResultats extends StatelessWidget {
  final String depart;
  final String arrivee;
  final List<Trajet> trajets;

  const PageResultats({
    required this.depart,
    required this.arrivee,
    required this.trajets,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Color(0xFF4EE2C0),
        elevation: 0,
        title: Row(
          children: [
            Text(depart, style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(width: 8),
            Icon(Icons.compare_arrows, color: Colors.white),
            SizedBox(width: 8),
            Text(arrivee, style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: trajets.length,
          itemBuilder: (context, i) {
            final t = trajets[i];
            return Card(
              margin: EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Icon(Icons.radio_button_checked, color: Colors.green),
                        Container(
                          width: 2,
                          height: 30,
                          color: Colors.grey[300],
                        ),
                        Icon(Icons.location_on, color: Colors.pink),
                      ],
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.depart, style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Métro ${t.ligne.split('→').first.trim()}', style: TextStyle(color: Colors.grey[700])),
                          SizedBox(height: 8),
                          Text(t.arrivee, style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Métro ${t.ligne.split('→').last.trim()}', style: TextStyle(color: Colors.grey[700])),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    Column(
                      children: [
                        Icon(Icons.train, size: 48, color: Color(0xFF4EE2C0)),
                        SizedBox(height: 4),
                        Text(t.position, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

Map<String, List<Map<String, String>>> construireGraphe(List<dynamic> data) {
  final Map<String, List<Map<String, String>>> graphe = {};
  for (final entry in data) {
    final from = entry['from_name'];
    final to = entry['to_name'];
    final ligne = entry['line_name'];
    graphe.putIfAbsent(from, () => []);
    graphe[from]!.add({'station': to, 'ligne': ligne});
    graphe.putIfAbsent(to, () => []);
    graphe[to]!.add({'station': from, 'ligne': ligne});
  }
  return graphe;
}

List<Map<String, String>> itineraire(
    Map<String, List<Map<String, String>>> graphe,
    String depart,
    String arrivee,
) {
  final queue = <List<Map<String, String>>>[];
  final visited = <String>{depart};
  queue.add([{'station': depart, 'ligne': ''}]);

  while (queue.isNotEmpty) {
    final path = queue.removeAt(0);
    final last = path.last['station']!;
    if (last == arrivee) return path;

    for (final voisin in graphe[last] ?? []) {
      final nextStation = voisin['station']!;
      if (!visited.contains(nextStation)) {
        visited.add(nextStation);
        queue.add([...path, voisin]);
      }
    }
  }
  return [];
}