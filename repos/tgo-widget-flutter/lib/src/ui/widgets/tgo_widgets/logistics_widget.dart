import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/tgo_theme.dart';
import './models/widget_types.dart';
import './shared/shared.dart';

class LogisticsWidget extends StatelessWidget {
  final LogisticsWidgetData data;
  final SendMessageCallback? onSendMessage;
  final ActionCallback? onAction;
  final ValueChanged<String>? onCopySuccess;

  const LogisticsWidget({
    super.key,
    required this.data,
    this.onSendMessage,
    this.onAction,
    this.onCopySuccess,
  });

  @override
  Widget build(BuildContext context) {
    final theme = TgoThemeProvider.of(context);

    return WidgetCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          WidgetHeader(
            icon: data.carrierLogo != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      data.carrierLogo!,
                      width: 20,
                      height: 20,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(Icons.local_shipping_outlined, color: const Color(0xFF9333EA), size: 20),
            iconBgColor: const Color(0xFFF5F3FF),
            title: data.carrier,
            subtitle: data.trackingNumber,
            badge: StatusBadge(
              text: data.statusText ?? data.status.name,
            ),
          ),

          const SizedBox(height: 16),

          // Estimated delivery
          if (data.estimatedDelivery != null)
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, color: Color(0xFF16A34A), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Estimated delivery: ${data.estimatedDelivery}',
                    style: const TextStyle(fontSize: 14, color: Color(0xFF16A34A)),
                  ),
                ],
              ),
            ),

          // Courier info
          if (data.courierName != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.bgSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 14, color: theme.textSecondary),
                      children: [
                        const TextSpan(text: 'Courier: '),
                        TextSpan(
                          text: data.courierName,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: theme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (data.courierPhone != null)
                    InkWell(
                      onTap: () => _launchPhone(data.courierPhone!),
                      child: Row(
                        children: [
                          Icon(Icons.phone_outlined, size: 16, color: theme.primaryColor),
                          const SizedBox(width: 4),
                          Text(
                            data.courierPhone!,
                            style: TextStyle(fontSize: 14, color: theme.primaryColor),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

          // Timeline
          _buildTimeline(theme),

          // Actions
          if (data.actions != null && data.actions!.isNotEmpty)
            ActionButtons(
              actions: data.actions,
              onSendMessage: onSendMessage,
              onAction: onAction,
              onCopySuccess: onCopySuccess,
            ),
        ],
      ),
    );
  }

  Widget _buildTimeline(TgoTheme theme) {
    if (data.timeline.isEmpty) return const SizedBox.shrink();

    return Column(
      children: List.generate(data.timeline.length, (index) {
        final event = data.timeline[index];
        final isFirst = index == 0;
        final isLast = index == data.timeline.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getEventColor(event, isFirst),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.bgPrimary,
                        blurRadius: 0,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: theme.borderPrimary,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.time,
                      style: TextStyle(fontSize: 12, color: theme.textMuted),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.description,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isFirst ? FontWeight.w500 : FontWeight.w400,
                        color: isFirst ? theme.textPrimary : theme.textSecondary,
                      ),
                    ),
                    if (event.location != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 12, color: theme.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              event.location!,
                              style: TextStyle(fontSize: 12, color: theme.textMuted),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Color _getEventColor(LogisticsEvent event, bool isFirst) {
    if (event.status != null) {
      switch (event.status!) {
        case LogisticsStatus.pending:
          return const Color(0xFF9CA3AF);
        case LogisticsStatus.picked_up:
          return const Color(0xFF3B82F6);
        case LogisticsStatus.in_transit:
          return const Color(0xFFA855F7);
        case LogisticsStatus.out_for_delivery:
          return const Color(0xFFF97316);
        case LogisticsStatus.delivered:
          return const Color(0xFF22C55E);
        case LogisticsStatus.exception:
          return const Color(0xFFEF4444);
        case LogisticsStatus.returned:
          return const Color(0xFF6B7280);
      }
    }
    return isFirst ? const Color(0xFF3B82F6) : const Color(0xFFE5E7EB);
  }

  Future<void> _launchPhone(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
}

