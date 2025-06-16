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

    setState(() {
      trajets = trajetsList;
      toutesLesStations = stations.toList()..sort();
    });
  }

  void rechercherTrajets() {
    // D'abord chercher les trajets directs
    final trajetsDirecs = trajets.where((t) =>
      t.depart == stationDepart && t.arrivee == stationArrivee
    ).toList();

    // Si pas de trajets directs, chercher avec correspondances
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

    // Limiter à 5 résultats
    final correspondances = resultats.take(5).toList();

    // Créer une liste formatée pour l'affichage
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
          : SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
                  child: Container(
                    padding: EdgeInsets.all(20),
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
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 25),
                        Row(
                          children: [
                            Icon(Icons.radio_button_checked, color: Colors.green),
                            SizedBox(width: 8),
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
                                      hintText: 'Ex : Gare Saint Lazare',
                                      hintStyle: TextStyle(fontStyle: FontStyle.italic),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Colors.pink),
                            SizedBox(width: 8),
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
                                      hintText: 'Ex : République',
                                      hintStyle: TextStyle(fontStyle: FontStyle.italic),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 25),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.green,
                                side: BorderSide(color: Colors.green),
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: (stationDepart != null && stationArrivee != null)
                                  ? rechercherTrajets
                                  : null,
                              child: Text("Trajets directs"),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: (stationDepart != null && stationArrivee != null)
                                  ? rechercherAvecCorrespondance
                                  : null,
                              child: Text("Avec correspondances"),
                            ),
                          ],
                        ),
                        SizedBox(height: 30),
                        if (trajetsFiltres.isNotEmpty) ...[
                          Text(
                            "Résultats :",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          for (final t in trajetsFiltres)
                            Card(
                              elevation: 3,
                              margin: EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: t.ligne.contains('→') ? Colors.orange : Colors.blue,
                                  child: Icon(
                                    t.ligne.contains('→') ? Icons.swap_horiz : Icons.train,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                title: Text('${t.depart} → ${t.arrivee}'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Ligne(s) : ${t.ligne}'),
                                    Text('${t.position}', 
                                         style: TextStyle(fontWeight: FontWeight.w500)),
                                  ],
                                ),
                                isThreeLine: true,
                              ),
                            ),
                        ],
                        if (trajetsFiltres.isEmpty && stationDepart != null && stationArrivee != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 20.0),
                            child: Column(
                              children: [
                                Text("Aucun trajet trouvé.",
                                    style: TextStyle(color: Colors.grey)),
                                SizedBox(height: 10),
                                Text("Essayez de chercher avec correspondances.",
                                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}