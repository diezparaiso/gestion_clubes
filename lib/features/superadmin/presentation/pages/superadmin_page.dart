import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';

class SuperadminPage extends StatefulWidget {
  const SuperadminPage({super.key});
  @override
  State<SuperadminPage> createState() => _SuperadminPageState();
}
class _SuperadminPageState extends State<SuperadminPage> {
  late Future<List<Map<String, dynamic>>> report;
  bool get isAdmin => SupabaseService.isConfigured &&
      Supabase.instance.client.auth.currentUser?.appMetadata['platform_admin'] == true;
  @override
  void initState() { super.initState(); report = load(); }
  Future<List<Map<String, dynamic>>> load() async {
    if (!isAdmin) return [];
    final rows = await Supabase.instance.client.rpc('get_platform_admin_report');
    return (rows as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
  void exportCsv(List<Map<String, dynamic>> clubs) {
    const headers = ['Club', 'Slug', 'Estado', 'Operaciones', 'Ventas brutas EUR', 'Reembolsos EUR', 'Comision bruta EUR', 'Comision neta estimada EUR', 'Tasa'];
    String cell(dynamic value) {
      final text = value?.toString() ?? '';
      return '"${text.replaceAll('"', '""')}"';
    }
    final rows = <List<dynamic>>[headers];
    for (final club in clubs) {
      rows.add([
        club['club_name'], club['club_slug'], club['club_status'], club['sales_count'],
        club['gross_sales'], club['refunded_sales'], club['commission_generated'],
        club['commission_net'], n(club['commission_rate']) * 100,
      ]);
    }
    final csv = '\uFEFF' + rows.map((row) => row.map(cell).join(';')).join('\r\n');
    final blob = html.Blob([utf8.encode(csv)], 'text/csv;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)..download = 'informe_comisiones_${DateTime.now().toIso8601String().substring(0, 10)}.csv'..style.display = 'none';
    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }

  double n(dynamic x) => x is num ? x.toDouble() : double.tryParse('$x') ?? 0;
  String eur(dynamic x) => '${n(x).toStringAsFixed(2).replaceAll('.', ',')} €';
  @override
  Widget build(BuildContext context) {
    if (!isAdmin) return Scaffold(appBar: AppBar(title: const Text('Superadmin')),
      body: const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Acceso restringido. Se requiere el claim seguro app_metadata.platform_admin=true.'))));
    return Scaffold(
      appBar: AppBar(title: const Text('Superadmin · Plataforma'),
        actions: [IconButton(tooltip: 'Exportar CSV', onPressed: () { final data = report; data.then((rows) => exportCsv(rows)); }, icon: const Icon(Icons.download_outlined)), IconButton(tooltip: 'Actualizar', onPressed: () => setState(() => report = load()), icon: const Icon(Icons.refresh))]),
      body: FutureBuilder<List<Map<String, dynamic>>>(future: report, builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snap.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('No se pudo cargar el informe de comisiones.'), const SizedBox(height: 8),
          Text('${snap.error}', textAlign: TextAlign.center),
          TextButton(onPressed: () => setState(() => report = load()), child: const Text('Reintentar'))])));
        final clubs = snap.data ?? [];
        final gross = clubs.fold<double>(0, (s, c) => s + n(c['gross_sales']));
        final refunds = clubs.fold<double>(0, (s, c) => s + n(c['refunded_sales']));
        final commission = clubs.fold<double>(0, (s, c) => s + n(c['commission_generated']));
        final net = clubs.fold<double>(0, (s, c) => s + n(c['commission_net']));
        final count = clubs.fold<int>(0, (s, c) => s + ((c['sales_count'] as num?)?.toInt() ?? 0));
        return LayoutBuilder(builder: (context, box) {
          final columns = box.maxWidth >= 1000 ? 4 : box.maxWidth >= 600 ? 2 : 1;
          return ListView(padding: const EdgeInsets.all(24), children: [
            const Text('Resumen económico', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('Ventas brutas y comisión de plataforma. Tasa inicial: 5 %.'),
            const SizedBox(height: 20),
            GridView.count(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: columns, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: columns == 1 ? 3.2 : 1.8,
              children: [
                _Metric('Clubes', '${clubs.length}', Icons.groups_outlined),
                _Metric('Ventas registradas', '$count', Icons.receipt_long_outlined),
                _Metric('Ventas brutas', eur(gross), Icons.account_balance_wallet_outlined),
                _Metric('Reembolsos', eur(refunds), Icons.undo),
                _Metric('Comisión bruta', eur(commission), Icons.trending_up),
                _Metric('Comisión neta estimada', eur(net), Icons.summarize_outlined),
              ]),
            const SizedBox(height: 26),
            const Text('Detalle por club', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            if (clubs.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('No hay clubes o ventas registradas en el informe.')))
            else ...clubs.map((c) => Card(margin: const EdgeInsets.only(bottom: 10), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Expanded(child: Text('${c['club_name'] ?? 'Club sin nombre'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))), Chip(label: Text('${c['club_status'] ?? '—'}'))]),
              if (c['club_slug'] != null) Text('/${c['club_slug']}'),
              const SizedBox(height: 12),
              Wrap(spacing: 24, runSpacing: 12, children: [
                _Value('Ventas brutas', eur(c['gross_sales'])), _Value('Reembolsos', eur(c['refunded_sales'])),
                _Value('Comisión bruta', eur(c['commission_generated'])), _Value('Comisión neta estimada', eur(c['commission_net'])),
                _Value('Operaciones', '${c['sales_count'] ?? 0}'),
                _Value('Tasa aplicada', '${(n(c['commission_rate']) * 100).toStringAsFixed(2).replaceAll('.', ',')} %'),
              ]),
            ])))),
            const SizedBox(height: 12),
            const Text('La comisión neta es una estimación que descuenta reembolsos registrados; no acredita cobro ni conciliación.', style: TextStyle(color: Colors.black54)),
          ]);
        });
      }),
    );
  }
}
class _Metric extends StatelessWidget {
  const _Metric(this.label, this.value, this.icon);
  final String label, value; final IconData icon;
  @override Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
    Icon(icon, size: 30, color: const Color(0xFF168B68)), const SizedBox(width: 12),
    Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12)), const SizedBox(height: 5),
      Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
    ])),
  ])));
}
class _Value extends StatelessWidget {
  const _Value(this.label, this.value);
  final String label, value;
  @override Widget build(BuildContext context) => SizedBox(width: 175, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: Theme.of(context).textTheme.bodySmall), const SizedBox(height: 3), Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
  ]));
}
