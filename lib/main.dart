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
  String trouverPosition(String depart, String arrivee, String ligne) {
  try {
    final trajet = trajets.firstWhere(
      (t) => t.depart == depart && t.arrivee == arrivee && t.ligne == ligne,
    );
    return trajet.position;
  } catch (e) {
    return 'non précisée';
  }
}

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
  Map<String, Set<String>> lignesVersStations = {};

  for (var t in trajets) {
    lignesVersStations.putIfAbsent(t.ligne, () => {});
    lignesVersStations[t.ligne]!.add(t.depart);
    lignesVersStations[t.ligne]!.add(t.arrivee);
  }

for (var ligne in lignesVersStations.keys) {
  final stations = lignesVersStations[ligne]!;
  if (stations.contains(stationDepart) && stations.contains(stationArrivee)) {
    final trajet = trajets.firstWhere(
      (t) => t.depart == stationDepart && t.arrivee == stationArrivee && t.ligne == ligne,
      orElse: () {
        return Trajet(
          ligne: ligne,
          depart: stationDepart!,
          arrivee: stationArrivee!,
          position: 'non précisée',
        );
      },
    );

    setState(() {
      trajetsFiltres = [
        Trajet(
          ligne: trajet.ligne,
          depart: trajet.depart,
          arrivee: trajet.arrivee,
          position: 'Montée à ${trajet.position.toLowerCase()}',
          intermediaire: null,
        )
      ];
    });
    return;
  }
}


  Set<String> lignesDepart = {};
  Set<String> lignesArrivee = {};

  for (var ligne in lignesVersStations.entries) {
    if (ligne.value.contains(stationDepart)) lignesDepart.add(ligne.key);
    if (ligne.value.contains(stationArrivee)) lignesArrivee.add(ligne.key);
  }

  Map<String, Trajet> meilleursParCombinaison = {};
  Map<String, int> scoreParCombinaison = {};

  for (var ld in lignesDepart) {
    for (var la in lignesArrivee) {
      if (ld == la) continue;

      final intersections = lignesVersStations[ld]!.intersection(lignesVersStations[la]!);
      for (var correspondance in intersections) {
        final premier = trajets.firstWhere(
          (t) => t.depart == stationDepart && t.arrivee == correspondance && t.ligne == ld,
          orElse: () => Trajet(
            ligne: ld,
            depart: stationDepart!,
            arrivee: correspondance,
            position: '',
          ),
        );

        final second = trajets.firstWhere(
          (t) => t.depart == correspondance && t.arrivee == stationArrivee && t.ligne == la,
          orElse: () => Trajet(
            ligne: la,
            depart: correspondance,
            arrivee: stationArrivee!,
            position: '',
          ),
        );

        final combine = Trajet(
          ligne: '${ld} → ${la}',
          depart: stationDepart!,
          arrivee: stationArrivee!,
          position: 'Montée à ${trouverPosition(stationDepart!, correspondance, ld).toLowerCase()} → ${trouverPosition(correspondance, stationArrivee!, la).toLowerCase()}',
          intermediaire: correspondance,
        );

        final cle = '${ld}_${la}';
        final score = 1; 

        if (!meilleursParCombinaison.containsKey(cle) || score < scoreParCombinaison[cle]!) {
          meilleursParCombinaison[cle] = combine;
          scoreParCombinaison[cle] = score;
        }
      }
    }
  }

 final correspondances = meilleursParCombinaison.values.toList();

if (correspondances.isNotEmpty) {
  setState(() {
    trajetsFiltres = correspondances.take(5).toList();
  });
} else {
  rechercherTrajetsAvecDeuxCorrespondances(lignesVersStations);
}

}
void rechercherTrajetsAvecDeuxCorrespondances(Map<String, Set<String>> lignesVersStations) {
  Set<String> lignesDepart = {};
  Set<String> lignesArrivee = {};

  for (var ligne in lignesVersStations.entries) {
    if (ligne.value.contains(stationDepart)) lignesDepart.add(ligne.key);
    if (ligne.value.contains(stationArrivee)) lignesArrivee.add(ligne.key);
  }

  List<Trajet> resultats = [];

  for (var ld in lignesDepart) {
    for (var li in lignesVersStations.keys) {
      if (li == ld) continue;

      final inter1s = lignesVersStations[ld]!.intersection(lignesVersStations[li]!);
      for (var inter1 in inter1s) {
        for (var la in lignesArrivee) {
          if (la == li || la == ld) continue;

          final inter2s = lignesVersStations[li]!.intersection(lignesVersStations[la]!);
          for (var inter2 in inter2s) {
            final pos1 = trouverPosition(stationDepart!, inter1, ld);
            final pos2 = trouverPosition(inter1, inter2, li);
            final pos3 = trouverPosition(inter2, stationArrivee!, la);

            final ligneCombinee = '$ld → $li → $la';
            final positionCombinee =
            'Montée à ${pos1.toLowerCase()} → ${pos2.toLowerCase()} → ${pos3.toLowerCase()}';


            final combine = Trajet(
              ligne: ligneCombinee,
              depart: stationDepart!,
              arrivee: stationArrivee!,
              position: positionCombinee,
              intermediaire: '$inter1 (L$li), $inter2 (L$la)',

            );

            resultats.add(combine);
          }
        }
      }
    }
  }

  if (resultats.isNotEmpty) {
    setState(() {
      trajetsFiltres = resultats.take(5).toList();
    });
  }
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
if (t.intermediaire != null) ...[
  for (final step in t.intermediaire!.split(',')) ...[
    Container(width: 2, height: 20, color: Colors.grey[300]),
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.radio_button_unchecked, color: Colors.orange, size: 14),
        SizedBox(width: 4),
        SizedBox(
          width: 60,
          child: Text(
            step.trim(),
            style: TextStyle(fontSize: 10, color: Colors.orange[800]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  ],
],



                        Container(width: 2, height: 30, color: Colors.grey[300]),
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
                          if (t.intermediaire != null) ...[
  Text(
    'Correspondance${t.intermediaire!.contains(',') ? 's' : ''} :',
    style: TextStyle(color: Colors.orange[700], fontSize: 12),
  ),
  for (final step in t.intermediaire!.split(',')) 
    Text(
      step.trim(),
      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[800], fontSize: 13),
    ),
  SizedBox(height: 8),
],

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
                        Text(
                          t.position,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
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