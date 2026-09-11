import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cora/main.dart';
import 'package:cora/models/traveler_profile.dart';

void main() {
  testWidgets('first visit saves profile before home', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const CoraApp());
    await tester.pumpAndSettle();
    expect(find.text('¡Hola! Soy CORA. ¿Cómo te llamas?'), findsOneWidget);
    expect(find.byTooltip('Enviar mensaje'), findsNothing);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe tu nombre.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Alex');
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Guatemala');
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Continuar'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Surf'));
    await tester.scrollUntilVisible(find.text('Empezar mi viaje'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Empezar mi viaje'));
    await tester.pumpAndSettle();
    expect(find.text('¡Hola, Alex!'), findsOneWidget);
    final storage = await SharedPreferences.getInstance();
    final profile = TravelerProfile.fromJson(
        jsonDecode(storage.getString('cora.traveler.v1')!));
    expect(profile.language, 'en');
    expect(profile.toContext()['intereses'], 'Surf');
    await tester.tap(find.text('Divisas'));
    await tester.pumpAndSettle();
    expect(find.text('Convertir'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '-1');
    await tester.drag(find.byType(ListView), const Offset(0, -250));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Convertir'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.textContaining('Escribe un monto'), 100, scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('Escribe un monto'), findsOneWidget);
  });
  testWidgets('returning traveler sees home and filters market',
      (tester) async {
    const profile = TravelerProfile(
        id: 'test',
        name: 'Ana',
        country: 'El Salvador',
        language: 'es',
        budget: '30–70',
        interests: ['Surf']);
    SharedPreferences.setMockInitialValues(
        {'cora.traveler.v1': jsonEncode(profile.toJson())});
    await tester.pumpWidget(const CoraApp());
    await tester.pumpAndSettle();
    expect(find.text('¡Hola, Ana!'), findsOneWidget);
    await tester.tap(find.text('Market'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Cultura'));
    await tester.pumpAndSettle();
    expect(find.text('Calles que cuentan historias'), findsOneWidget);
    expect(find.text('Tu primera ola'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
