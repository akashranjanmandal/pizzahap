import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/admin_api_service.dart';
import '../../config/app_config.dart';
import '../../widgets/widgets.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _stats;
  List<dynamic> _reports = [];
  String _period = 'daily';
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        AdminApiService.getDashboard(),
        AdminApiService.getReports(period: _period),
      ]);
      _stats = results[0] as Map<String, dynamic>;
      _reports = results[1] as List<dynamic>;
    } catch (e) {
      if (mounted) showSnack(context, 'Failed to load dashboard', isError: true);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(AppColors.background),
    appBar: AppBar(
      title: const Text('Dashboard'),
      actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        Builder(builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        )),
      ],
    ),
    body: _loading
      ? const Center(child: CircularProgressIndicator(color: Color(AppColors.primary)))
      : RefreshIndicator(
          color: const Color(AppColors.primary),
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // KPI cards
              GridView.count(
                crossAxisCount: 2, shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12, mainAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  _KpiCard(label: "Today's Orders", value: '${_stats?['today']?['orders'] ?? 0}',
                    icon: '📦', color: Colors.blue),
                  _KpiCard(label: "Today's Revenue", value: '₹${_stats?['today']?['revenue'] ?? '0'}',
                    icon: '💰', color: const Color(AppColors.success)),
                  _KpiCard(label: 'Pending Orders', value: '${_stats?['pending_orders'] ?? 0}',
                    icon: '⏳', color: const Color(AppColors.warning)),
                  _KpiCard(label: 'New Users Today', value: '${_stats?['new_users_today'] ?? 0}',
                    icon: '👤', color: Colors.purple),
                ],
              ),
              const SizedBox(height: 16),

              // Total revenue card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(AppColors.primaryDark), Color(AppColors.primary)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Text('💵', style: TextStyle(fontSize: 32)),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Revenue', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        Text('₹${_stats?['total_revenue'] ?? '0'}',
                          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Revenue chart
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Revenue Trend', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        DropdownButton<String>(
                          value: _period,
                          underline: const SizedBox(),
                          style: const TextStyle(fontSize: 13, color: Color(AppColors.textPrimary), fontWeight: FontWeight.w600),
                          items: ['daily', 'weekly', 'monthly'].map((p) =>
                            DropdownMenuItem(value: p, child: Text(p))).toList(),
                          onChanged: (v) { setState(() => _period = v!); _load(); },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 180,
                      child: _reports.isEmpty
                        ? const Center(child: Text('No data'))
                        : LineChart(LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawHorizontalLine: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(sideTitles: SideTitles(
                                showTitles: true, reservedSize: 20,
                                getTitlesWidget: (v, _) {
                                  final i = v.toInt();
                                  if (i < 0 || i >= _reports.length) return const SizedBox();
                                  final p = _reports[i]['period'].toString();
                                  return Text(p.length > 5 ? p.substring(p.length - 5) : p,
                                    style: TextStyle(fontSize: 9, color: Colors.grey.shade500));
                                },
                              )),
                            ),
                            borderData: FlBorderData(show: false),
                            // lineBarsData: [
                            //   LineChartBarData(
                            //     spots: _reports.asMap().entries.map((e) =>
                            //       FlSpot(e.key.toDouble(), (e.value['revenue'] ?? 0))).toList(),
                            //     isCurved: true,
                            //     color: const Color(AppColors.primary),
                            //     barWidth: 2.5,
                            //     dotData: const FlDotData(show: false),
                            //     belowBarData: BarAreaData(
                            //       show: true,
                            //       color: const Color(AppColors.primary).withOpacity(0.08),
                            //     ),
                            //   ),
                            // ],
                          )),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Popular products
              if (_stats?['popular_products'] != null) ...[
                const Text('🔥 Top Products', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 10),
                ...(_stats!['popular_products'] as List).map((p) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                  ),
                  child: Row(
                    children: [
                      PizzaNetImage(url: p['image_url'], width: 44, height: 44, borderRadius: BorderRadius.circular(8)),
                      const SizedBox(width: 10),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          Text('${p['order_count']} orders', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        ],
                      )),
                      Text('₹${(p['revenue'] ?? 0)}',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: Color(AppColors.primary))),
                    ],
                  ),
                )),
              ],
              const SizedBox(height: 80),
            ],
          ),
        ),
  );
}

class _KpiCard extends StatelessWidget {
  final String label, value, icon;
  final Color color;
  const _KpiCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: color)),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    ),
  );
}
