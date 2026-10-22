import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/sensor_provider.dart';
import '../../../models/alert_item.dart';
import '../../../shared/widgets/empty_state_view.dart';
import '../../../shared/widgets/loading_indicator.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Alerts & Warnings'),
      ),
      body: Consumer<SensorProvider>(
        builder: (context, provider, child) {
          if (provider.isLoadingDashboard && provider.dashboard == null) {
            return const LoadingIndicator(message: 'Checking active alerts...');
          }

          final alerts = provider.dashboard?.alerts ?? [];

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () => provider.fetchDashboard(),
            child: alerts.isEmpty
                ? const EmptyStateView(
                    title: 'All Systems Normal',
                    message: 'No active critical alerts or threshold breaches detected across sensors.',
                    icon: Icons.check_circle_outline_rounded,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: alerts.length,
                    itemBuilder: (context, index) {
                      final alert = alerts[index];
                      return _buildAlertCard(context, alert);
                    },
                  ),
          );
        },
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context, AlertItem alert) {
    Color severityColor;
    IconData icon;

    switch (alert.severity) {
      case 'CRITICAL':
        severityColor = AppColors.critical;
        icon = Icons.error_outline_rounded;
        break;
      case 'WARNING':
        severityColor = AppColors.warning;
        icon = Icons.warning_amber_rounded;
        break;
      case 'ERROR':
        severityColor = Colors.deepPurple;
        icon = Icons.bug_report_outlined;
        break;
      case 'INFO':
      default:
        severityColor = AppColors.info;
        icon = Icons.info_outline_rounded;
        break;
    }

    final timeStr = alert.timestamp != null
        ? DateFormat('HH:mm:ss · MMM dd').format(alert.timestamp!.toLocal())
        : 'Active';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Card(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: severityColor.withOpacity(0.3), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: severityColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: severityColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              alert.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: severityColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                alert.severity,
                                style: TextStyle(
                                  color: severityColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timeStr,
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                alert.message,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
              if (alert.sensorValue != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Trigger Value: ${alert.sensorValue} ${alert.unit ?? ""}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: severityColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
