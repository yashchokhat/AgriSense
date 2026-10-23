import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/device_status.dart';

class ConnectivityBanner extends StatefulWidget {
  final DeviceStatus device;
  final VoidCallback? onRefresh;

  const ConnectivityBanner({
    super.key,
    required this.device,
    this.onRefresh,
  });

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final device = widget.device;
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (!device.isOnline) {
      statusColor = AppColors.critical;
      statusText = 'OFFLINE';
      statusIcon = Icons.cloud_off_rounded;
    } else if (device.isStale) {
      statusColor = AppColors.stale;
      statusText = 'DATA STALE';
      statusIcon = Icons.history_rounded;
    } else {
      statusColor = AppColors.online;
      statusText = 'LIVE TELEMETRY';
      statusIcon = Icons.sensors_rounded;
    }

    final timeStr = device.lastSeenTimestamp != null
        ? DateFormat('HH:mm:ss').format(device.lastSeenTimestamp!.toLocal())
        : 'Never';

    final isLive = device.isOnline && !device.isStale;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.25), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Pulsing live beacon or solid status indicator
              if (isLive)
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: _pulseAnimation.value),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.4 * _pulseAnimation.value),
                            blurRadius: 6,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    );
                  },
                )
              else
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
              const SizedBox(width: 8),
              Icon(statusIcon, size: 14, color: statusColor),
              const SizedBox(width: 6),
              Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              Icon(Icons.wifi_rounded, size: 14, color: statusColor),
              const SizedBox(width: 4),
              Text(
                device.wifiRssiDbm != null ? '${device.wifiRssiDbm} dBm' : 'No Signal',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (widget.onRefresh != null) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: widget.onRefresh,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(Icons.refresh_rounded, size: 15, color: statusColor),
                  ),
                ),
              ],
            ],
          ),
          if (device.isStale) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.info_outline, size: 12, color: statusColor),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Last broadcast observed ${device.secondsSinceLastSeen.toInt()}s ago (at $timeStr).',
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
