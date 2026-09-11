import 'package:flutter/material.dart';

class TourismExperience {
  final String name, place, category, description;
  final int price;
  final IconData icon;
  const TourismExperience(this.name, this.place, this.category,
      this.description, this.price, this.icon);
}

const demoExperiences = [
  TourismExperience(
      'Tu primera ola',
      'El Tunco · La Libertad',
      'Surf',
      'Ejemplo de una clase introductoria de surf, con tabla e instructor. Duración sugerida: 90 minutos. Confirma condiciones del mar, equipo y disponibilidad con un operador real.',
      35,
      Icons.surfing),
  TourismExperience(
      'Sabores de nuestra tierra',
      'Suchitoto · Cuscatlán',
      'Gastronomía',
      'Ejemplo de un taller de pupusas para conocer ingredientes y técnicas locales. Actividad de demostración para el catálogo; no hay un negocio contratado.',
      18,
      Icons.restaurant),
  TourismExperience(
      'Entre volcanes y nubes',
      'Santa Ana',
      'Aventura',
      'Ejemplo de una experiencia guiada de senderismo. Una visita real requiere comprobar acceso, clima, guía, nivel físico y tarifas vigentes.',
      40,
      Icons.landscape),
  TourismExperience(
      'Una pausa junto al lago',
      'Lago de Coatepeque',
      'Naturaleza',
      'Ejemplo de un paseo tranquilo y tiempo para disfrutar del paisaje. Transporte y alimentación se confirmarían al contactar con un proveedor real.',
      25,
      Icons.water),
  TourismExperience(
      'Calles que cuentan historias',
      'Suchitoto',
      'Cultura',
      'Ejemplo de un recorrido cultural por calles y espacios locales. La ruta, los horarios y las entradas son ilustrativos.',
      20,
      Icons.account_balance),
  TourismExperience(
      'Atardecer en la costa',
      'El Zonte · La Libertad',
      'Playa',
      'Ejemplo de una experiencia para conocer la costa a tu ritmo. No incluye transporte ni una reserva confirmada.',
      15,
      Icons.wb_sunny_outlined),
];

class MarketScreen extends StatefulWidget {
  final ValueChanged<String> askCora;
  const MarketScreen({super.key, required this.askCora});
  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  String _category = 'Todo', _query = '';
  void _details(TourismExperience e) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(e.icon, size: 56, color: const Color(0xFF007F79)),
                const SizedBox(height: 16),
                Text(e.name,
                    style: const TextStyle(
                        fontSize: 27, fontWeight: FontWeight.bold)),
                Text(e.place),
                const SizedBox(height: 18),
                Text(e.description),
                const SizedBox(height: 20),
                Text('Precio de ejemplo: USD ${e.price} / persona',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text(
                    'Catálogo demo · Sin cobros ni reservas. Precios ilustrativos.',
                    style: TextStyle(fontSize: 12)),
                const SizedBox(height: 20),
                SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          widget.askCora(
                              'Me interesa ${e.category.toLowerCase()} en ${e.place}. Vi la experiencia de demostración «${e.name}». ¿Qué debería tener en cuenta para planear una actividad así?');
                        },
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('Planear algo así con CORA'))),
              ])));

  @override
  Widget build(BuildContext context) {
    final entries = demoExperiences
        .where((e) =>
            (_category == 'Todo' || e.category == _category) &&
            '${e.name} ${e.place} ${e.category}'
                .toLowerCase()
                .contains(_query.toLowerCase()))
        .toList();
    return ListView(padding: const EdgeInsets.all(24), children: [
      const Text('Experiencias\ncon sabor local.',
          style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      const Text('Encuentra inspiración para tu próxima aventura.'),
      const SizedBox(height: 12),
      const Text('CATÁLOGO DEMO · PRECIOS ILUSTRATIVOS',
          style: TextStyle(
              fontSize: 10, letterSpacing: 1, color: Color(0xFF53665F))),
      const SizedBox(height: 20),
      TextField(
          decoration: const InputDecoration(
              hintText: 'Busca un lugar o experiencia',
              prefixIcon: Icon(Icons.search)),
          onChanged: (v) => setState(() => _query = v)),
      const SizedBox(height: 16),
      Wrap(
          spacing: 8,
          children: [
            'Todo',
            'Surf',
            'Playa',
            'Aventura',
            'Gastronomía',
            'Cultura',
            'Naturaleza'
          ]
              .map((c) => ChoiceChip(
                  label: Text(c),
                  selected: _category == c,
                  onSelected: (_) => setState(() => _category = c)))
              .toList()),
      const SizedBox(height: 18),
      if (entries.isEmpty)
        const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
                'No encontramos experiencias. Prueba otra categoría o búsqueda.')),
      ...entries.map((e) => Card(
          margin: const EdgeInsets.only(bottom: 16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
              onTap: () => _details(e),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        height: 112,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: [
                          Color(0xFFDCEEE6),
                          Color(0xFFEFE6C8)
                        ])),
                        child: Icon(e.icon,
                            size: 60, color: const Color(0xFF18766A))),
                    Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.category.toUpperCase(),
                                  style: const TextStyle(
                                      fontSize: 10,
                                      letterSpacing: 1.5,
                                      color: Color(0xFF007F79))),
                              const SizedBox(height: 6),
                              Text(e.name,
                                  style: const TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(e.place),
                              const SizedBox(height: 14),
                              Row(children: [
                                Expanded(
                                    child: Text('USD ${e.price} · ejemplo',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600))),
                                const Icon(Icons.arrow_forward)
                              ]),
                            ])),
                  ])))),
    ]);
  }
}
