import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/device_status.dart';

class ConnectivityBanner extends StatelessWidget {
  final DeviceStatus device;
  final VoidCallback? onRefresh;

  const ConnectivityBanner({
    super.key,
    required this.device,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (!device.isOnline) {
      statusColor = AppColors.critical;
      statusText = 'OFFLINE';
      statusIcon = Icons.signal_wifi_off_rounded;
    } else if (device.isStale) {
      statusColor = AppColors.stale;
      statusText = 'DATA STALE';
      statusIcon = Icons.access_time_rounded;
    } else {
      statusColor = AppColors.online;
      statusText = 'LIVE STREAM';
      statusIcon = Icons.wifi_tethering_rounded;
    }

    final timeStr = device.lastSeenTimestamp != null
        ? DateFormat('HH:mm:ss').format(device.lastSeenTimestamp!.toLocal())
        : 'Never';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.25), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(statusIcon, size: 14, color: statusColor),
              const SizedBox(width: 6),
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Icon(Icons.wifi_rounded, size: 16, color: statusColor),
              const SizedBox(width: 4),
              Text(
                device.wifiRssiDbm != null ? '${device.wifiRssiDbm} dBm' : 'No Signal',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (onRefresh != null) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: onRefresh,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(Icons.refresh_rounded, size: 16, color: statusColor),
                  ),
                ),
              ],
            ],
          ),
          if (device.isStale) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.info_outline, size: 13, color: statusColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'No new sensor broadcast for ${device.secondsSinceLastSeen.toInt()}s (Last seen $timeStr).',
                    style: TextStyle(color: statusColor, fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
