import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:swe_mobile/core/providers/company_profile_provider.dart';
import 'package:swe_mobile/data/models/order.dart';
import 'package:swe_mobile/ui/supplier/models/dashboard_data.dart';
import 'package:swe_mobile/ui/supplier/view_models/dashboard_viewmodel.dart';

class SupplierDashboardView extends ConsumerWidget {
  const SupplierDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardViewModelProvider);
    final companyState = ref.watch(companyProfileProvider);
    
    final companyId = companyState.when(
      data: (company) => company?.id,
      loading: () => null,
      error: (_, __) => null,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard ${companyId != null ? "(Co: $companyId)" : "(No Co)"}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(dashboardViewModelProvider.notifier).refresh(),
          ),
        ],
      ),
      body: dashboardState.when(
        data: (data) => RefreshIndicator(
          onRefresh: () => ref.read(dashboardViewModelProvider.notifier).refresh(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildKPIGrid(context, data),
                const SizedBox(height: 24),
                _buildSectionTitle(context, 'Revenue Trend'),
                const SizedBox(height: 16),
                _buildRevenueChart(context, data),
                const SizedBox(height: 24),
                _buildSectionTitle(context, 'Order Status'),
                const SizedBox(height: 16),
                _buildStatusPieChart(context, data),
                const SizedBox(height: 24),
                _buildSectionTitle(context, 'Recent Orders'),
                const SizedBox(height: 8),
                _buildRecentOrdersList(context, data),
                const SizedBox(height: 24),
                _buildSectionTitle(context, 'Low Stock Alert'),
                const SizedBox(height: 8),
                _buildLowStockList(context, data),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error loading dashboard: $error'),
              ElevatedButton(
                onPressed: () => ref.read(dashboardViewModelProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildKPIGrid(BuildContext context, DashboardData data) {
    // Format as KZT (Kazakhstani Tenge) with ₸ symbol
    final currencyFormat = NumberFormat.currency(symbol: '₸', decimalDigits: 0);
    
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _buildKPICard(
          context,
          'Total Revenue',
          currencyFormat.format(data.totalRevenue),
          Icons.attach_money,
          Colors.green,
        ),
        _buildKPICard(
          context,
          'Orders Today',
          data.ordersTodayCount.toString(),
          Icons.today,
          Colors.blue,
        ),
        _buildKPICard(
          context,
          'Created Orders',
          data.pendingOrdersCount.toString(),
          Icons.pending_actions,
          Colors.orange,
        ),
        _buildKPICard(
          context,
          'Low Stock',
          data.lowStockCount.toString(),
          Icons.warning_amber_rounded,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildKPICard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart(BuildContext context, DashboardData data) {
    if (data.revenueTrend.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No revenue data available')),
      );
    }

    final sortedKeys = data.revenueTrend.keys.toList()..sort();
    final spots = sortedKeys.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), data.revenueTrend[e.value]!.toDouble());
    }).toList();

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < sortedKeys.length) {
                    // Show date every few points to avoid crowding
                    if (sortedKeys.length > 7 && index % (sortedKeys.length ~/ 5) != 0) {
                       return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        DateFormat('MM/dd').format(sortedKeys[index]),
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                interval: 1,
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade300)),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Theme.of(context).primaryColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPieChart(BuildContext context, DashboardData data) {
    if (data.orderStatusDistribution.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No order data available')),
      );
    }

    final total = data.orderStatusDistribution.values.fold(0, (sum, count) => sum + count);
    
    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 40,
                sections: data.orderStatusDistribution.entries.map((e) {
                  final percentage = (e.value / total) * 100;
                  Color color;
                  switch (e.key) {
                    case OrderStatus.created: color = Colors.orange; break;
                    case OrderStatus.processing: color = Colors.blue; break;
                    case OrderStatus.shipping: color = Colors.indigo; break;
                    case OrderStatus.completed: color = Colors.green; break;
                    case OrderStatus.rejected: color = Colors.red; break;
                  }
                  
                  return PieChartSectionData(
                    color: color,
                    value: e.value.toDouble(),
                    title: '${percentage.toStringAsFixed(0)}%',
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data.orderStatusDistribution.entries.map((e) {
               Color color;
                  switch (e.key) {
                    case OrderStatus.created: color = Colors.orange; break;
                    case OrderStatus.processing: color = Colors.blue; break;
                    case OrderStatus.shipping: color = Colors.indigo; break;
                    case OrderStatus.completed: color = Colors.green; break;
                    case OrderStatus.rejected: color = Colors.red; break;
                  }
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Container(width: 12, height: 12, color: color),
                    const SizedBox(width: 8),
                    Text('${e.key.name} (${e.value})'),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrdersList(BuildContext context, DashboardData data) {
    if (data.recentOrders.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No recent orders')));
    }

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: data.recentOrders.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final order = data.recentOrders[index];
          return ListTile(
            title: Text('Order #${order.orderId}'),
            subtitle: Text(DateFormat('MMM dd, yyyy').format(DateTime.tryParse(order.createdAt) ?? DateTime.now())),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  NumberFormat.currency(symbol: '₸', decimalDigits: 0).format(order.totalPrice),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  order.status.name,
                  style: TextStyle(
                    color: order.status == OrderStatus.completed ? Colors.green : Colors.orange,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            onTap: () {
              // Navigate to order details
            },
          );
        },
      ),
    );
  }

  Widget _buildLowStockList(BuildContext context, DashboardData data) {
    if (data.lowStockProducts.isEmpty) {
      return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No low stock alerts')));
    }

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: data.lowStockProducts.length,
        itemBuilder: (context, index) {
          final product = data.lowStockProducts[index];
          return Container(
            width: 140,
            margin: const EdgeInsets.only(right: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: product.pictureUrls.isNotEmpty
                          ? Image.network(
                              product.pictureUrls.first,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
                            )
                          : const Icon(Icons.image, size: 40),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Stock: ${product.stockQuantity} / ${product.threshold}',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
