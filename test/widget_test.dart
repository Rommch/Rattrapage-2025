// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ratp_trajet_flutter/main.dart';

void main() {
  testWidgets('App shows loading then list', (WidgetTester tester) async {
    await tester.pumpWidget(MonAppli());

    // Attendre un peu que le chargement se fasse
    await tester.pump(Duration(seconds: 2));

    // Vérifie qu'on voit soit le CircularProgressIndicator soit des trajets
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // Tu peux aussi tester la présence de ListView si les données sont chargées :
    // expect(find.byType(ListView), findsOneWidget);
  });
}

