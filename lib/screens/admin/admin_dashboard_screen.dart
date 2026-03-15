import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/admin_provider.dart';
import '../../services/admin_api_service.dart';
import '../../config/app_config.dart';
import '../../widgets/widgets.dart';
import 'package:provider/provider.dart';

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
    if (mounted) setState(() => _loading = true);
    try {
      final results = await Future.wait([
        AdminApiService.getDashboard(),
        AdminApiService.getReports(period: _period),
      ]);
      if (mounted) {
        setState(() {
          _stats = results[0] as Map<String, dynamic>;
          _reports = results[1] as List<dynamic>;
        });
      }
    } catch (e) {
      if (mounted) showSnack(context, 'Failed to load dashboard', isError: true);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dashboard', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            Text(
              admin.adminLocationName != null ? '📍 ${admin.adminLocationName}' : 'All Locations',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
          // Logout button visible in app bar
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(AppColors.error)),
            onPressed: _showLogout,
            tooltip: 'Sign Out',
          ),
          Builder(builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                // Admin Welcome banner
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(AppColors.primaryDark), Color(AppColors.primary)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(
                      color: const Color(AppColors.primary).withOpacity(0.3),
                      blurRadius: 12, offset: const Offset(0, 4),
                    )],
                  ),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Welcome back,', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                      Text(admin.adminName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(admin.adminRole.replaceAll('_', ' '),
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                      ),
                    ])),
                    const Text('👨‍🍳', style: TextStyle(fontSize: 48)),
                  ]),
                ),
                const SizedBox(height: 20),

                // KPI grid — flexible height
                Row(children: [
                  Expanded(child: _KpiCard(
                    label: "Today's Orders",
                    value: '${_stats?['today']?['orders'] ?? 0}',
                    icon: Icons.shopping_bag_outlined, color: Colors.blue,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _KpiCard(
                    label: "Today's Revenue",
                    value: '₹${_stats?['today']?['revenue'] ?? 0}',
                    icon: Icons.currency_rupee_rounded, color: const Color(AppColors.success),
                  )),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _KpiCard(
                    label: 'Pending Orders',
                    value: '${_stats?['pending_orders'] ?? 0}',
                    icon: Icons.pending_actions_rounded, color: const Color(AppColors.warning),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _KpiCard(
                    label: 'New Users Today',
                    value: '${_stats?['new_users_today'] ?? 0}',
                    icon: Icons.person_add_outlined, color: Colors.purple,
                  )),
                ]),
                const SizedBox(height: 16),

                // Total revenue card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: const Color(AppColors.success).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.account_balance_wallet_outlined, color: Color(AppColors.success)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Total All-time Revenue', style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
                        Text('₹${_stats?['total_revenue'] ?? '0'}',
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(AppColors.success))),
                      ])),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Revenue chart
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('Revenue Trend', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(AppColors.background),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _period,
                              isDense: true,
                              style: const TextStyle(fontSize: 12, color: Color(AppColors.textPrimary), fontWeight: FontWeight.w600),
                              items: ['daily', 'weekly', 'monthly'].map((p) =>
                                DropdownMenuItem(value: p, child: Text(p))).toList(),
                              onChanged: (v) { if (v != null) { setState(() => _period = v); _load(); }},
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 160,
                        child: _reports.isEmpty
                          ? Center(child: Text('No data available', style: TextStyle(color: Colors.grey.shade400)))
                          : _buildChart(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Popular products
                if (_stats?['popular_products'] != null && (_stats!['popular_products'] as List).isNotEmpty) ...[
                  const Text('🔥 Top Products', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 10),
                  ...(_stats!['popular_products'] as List).take(5).map((p) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                    ),
                    child: Row(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: PizzaNetImage(url: p['image_url'], width: 44, height: 44),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('${p['order_count']} orders', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      ])),
                      Text('₹${p['revenue'] ?? 0}',
                        style: const TextStyle(fontWeight: FontWeight.w800, color: Color(AppColors.primary), fontSize: 14)),
                    ]),
                  )),
                ],
              ],
            ),
          ),
    );
  }

  Widget _buildChart() {
    final spots = _reports.asMap().entries.map((e) {
      final rev = e.value['revenue'];
      final val = rev is num ? rev.toDouble() : double.tryParse('$rev') ?? 0.0;
      return FlSpot(e.key.toDouble(), val);
    }).toList();

    return LineChart(LineChartData(
      gridData: FlGridData(
        show: true,
        drawHorizontalLine: true, drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.shade100, strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true, reservedSize: 22,
          getTitlesWidget: (v, _) {
            final i = v.toInt();
            if (i < 0 || i >= _reports.length) return const SizedBox();
            final p = _reports[i]['period'].toString();
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                p.length > 5 ? p.substring(p.length - 5) : p,
                style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
              ),
            );
          },
        )),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: const Color(AppColors.primary),
          barWidth: 2.5,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: const Color(AppColors.primary).withOpacity(0.08),
          ),
        ),
      ],
    ));
  }

  void _showLogout() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: const Color(AppColors.error).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout_rounded, color: Color(AppColors.error), size: 26),
            ),
            const SizedBox(height: 14),
            const Text('Sign Out?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 8),
            Text('You will be logged out of admin.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel'))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.read<AdminProvider>().logout();
                  Navigator.pushReplacementNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(AppColors.error)),
                child: const Text('Sign Out'),
              )),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _KpiCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 12),
        Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: color)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    ),
  );
}
