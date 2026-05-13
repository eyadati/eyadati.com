import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons/lucide_icons.dart';

class DoctorAppointmentCard extends StatelessWidget {
  final Map<String, dynamic> appointment;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onCancel;
  final VoidCallback? onAbsent;

  const DoctorAppointmentCard({
    super.key,
    required this.appointment,
    this.onTap,
    this.onComplete,
    this.onCancel,
    this.onAbsent,
  });

  @override
  Widget build(BuildContext context) {
    final patientName = appointment['patient_name'] ?? 'Unknown';
    final phone = appointment['phone'] ?? '';
    final date = appointment['date'] != null 
        ? DateTime.tryParse(appointment['date'].toString()) 
        : null;
    final status = appointment['status'] ?? 'upcoming';
    final doctorName = appointment['doctor_name'];
    final isConsultation = appointment['is_consultation'] ?? false;

    final timeString = date != null 
        ? '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
        : '--:--';

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = LucideIcons.checkCircle;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = LucideIcons.xCircle;
        break;
      case 'absent':
        statusColor = Colors.orange;
        statusIcon = LucideIcons.userX;
        break;
      default:
        statusColor = Colors.blue;
        statusIcon = LucideIcons.clock;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.user,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      patientName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Icon(statusIcon, color: statusColor, size: 20),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(LucideIcons.phone, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(phone, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(LucideIcons.clock, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    timeString,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  if (doctorName != null) ...[
                    const SizedBox(width: 12),
                    Icon(LucideIcons.userCheck, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      doctorName,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ],
              ),
              if (isConsultation) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple.withAlpha(30),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'consultation'.tr(),
                    style: TextStyle(
                      color: Colors.purple[700],
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              if (onComplete != null || onCancel != null || onAbsent != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (status == 'upcoming') ...[
                      TextButton.icon(
                        onPressed: onComplete,
                        icon: const Icon(LucideIcons.check, size: 16),
                        label: Text('completed'.tr()),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: onAbsent,
                        icon: const Icon(LucideIcons.userX, size: 16),
                        label: Text('absent'.tr()),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: onCancel,
                        icon: const Icon(LucideIcons.x, size: 16),
                        label: Text('cancel'.tr()),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}