import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../core/config.dart';

class CurrencyScreen extends StatefulWidget {
  const CurrencyScreen({super.key});
  @override
  State<CurrencyScreen> createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  final _amount = TextEditingController(text: '100');
  final _client = http.Client();
  String _from = 'USD', _to = 'GTQ';
  bool _busy = false;
  String? _error;
  Map<String, dynamic>? _result;
  static const _currencies = {
    'USD': 'Dólar',
    'GTQ': 'Quetzal',
    'EUR': 'Euro',
    'MXN': 'Peso mexicano',
    'HNL': 'Lempira',
    'CRC': 'Colón costarricense',
    'CAD': 'Dólar canadiense',
    'GBP': 'Libra esterlina'
  };
  @override
  void dispose() {
    _amount.dispose();
    _client.close();
    super.dispose();
  }

  Future<void> _convert() async {
    final raw = _amount.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(raw);
    setState(() {
      _result = null;
      _error = null;
    });
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(raw) ||
        amount == null ||
        !amount.isFinite ||
        amount > 100000000) {
      setState(() => _error =
          'Escribe un monto de 0 a 100 millones, con hasta 2 decimales, sin separadores de miles.');
      return;
    }
    setState(() => _busy = true);
    try {
      final res = await _client
          .post(Uri.parse('${AppConfig.apiBaseUrl}/api/currency/convert'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'amount': amount, 'from': _from, 'to': _to}))
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) throw StateError('Unavailable');
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['result'] is! num ||
          data['rate'] is! num ||
          DateTime.tryParse(data['updatedAt'] as String) == null) {
        throw const FormatException();
      }
      if (mounted) setState(() => _result = data);
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'No pude consultar las tasas. Comprueba tu conexión e intenta de nuevo.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _selector(String label, String value, ValueChanged<String> onChange) =>
      DropdownButtonFormField<String>(
          initialValue: value,
          key: ValueKey('$label$value'),
          isExpanded: true,
          decoration: InputDecoration(labelText: label),
          items: _currencies.entries
              .map((e) => DropdownMenuItem(
                  value: e.key,
                  child: Text('${e.key} · ${e.value}',
                      overflow: TextOverflow.ellipsis)))
              .toList(),
          onChanged: _busy
              ? null
              : (v) {
                  if (v != null) {
                    setState(() {
                      onChange(v);
                      _result = null;
                    });
                  }
                });

  @override
  Widget build(BuildContext context) =>
      ListView(padding: const EdgeInsets.all(24), children: [
        const Text('Tu dinero,\nsin confusiones.',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        const Text(
            'Compara tu moneda con el dólar y prepara tu presupuesto de viaje.'),
        const SizedBox(height: 24),
        TextField(
            controller: _amount,
            enabled: !_busy,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
                labelText: 'Monto', prefixIcon: Icon(Icons.payments_outlined)),
            onChanged: (_) => setState(() => _result = null)),
        const SizedBox(height: 18),
        _selector('De', _from, (v) => _from = v),
        Align(
            alignment: Alignment.center,
            child: IconButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                          final previous = _from;
                          _from = _to;
                          _to = previous;
                          _result = null;
                        }),
                tooltip: 'Intercambiar monedas',
                icon: const Icon(Icons.swap_vert))),
        _selector('A', _to, (v) => _to = v),
        const SizedBox(height: 24),
        FilledButton(
            onPressed: _busy ? null : _convert,
            child: Text(_busy ? 'Consultando tasas…' : 'Convertir')),
        if (_error != null)
          Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(_error!,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error))),
        if (_result != null)
          Container(
              margin: const EdgeInsets.only(top: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: const Color(0xFFDCEEE6),
                  borderRadius: BorderRadius.circular(24)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        '${_result!['amount']} ${_result!['from']} equivale a'),
                    const SizedBox(height: 8),
                    Text(
                        '${(_result!['result'] as num).toStringAsFixed(2)} ${_result!['to']}',
                        style: const TextStyle(
                            fontSize: 30, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(
                        '1 ${_result!['from']} = ${(_result!['rate'] as num).toStringAsFixed(4)} ${_result!['to']}'),
                    const SizedBox(height: 8),
                    Text(
                        'Tasa del ${(_result!['updatedAt'] as String).substring(0, 10)} (UTC)'),
                  ])),
        const SizedBox(height: 20),
        const Text(
            'Conversión orientativa con tasas de actualización diaria. No incluye comisiones de bancos ni casas de cambio.',
            style: TextStyle(fontSize: 12)),
        TextButton(
            onPressed: () async {
              try {
                if (!await launchUrl(
                    Uri.parse('https://www.exchangerate-api.com'),
                    mode: LaunchMode.externalApplication)) {
                  throw StateError('Cannot open');
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content:
                          Text('Fuente: https://www.exchangerate-api.com')));
                }
              }
            },
            child: const Text('Rates By Exchange Rate API',
                style: TextStyle(fontSize: 12))),
      ]);
}
