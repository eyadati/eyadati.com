import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons/lucide_icons.dart';

class DoctorCalendarHeader extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? selectedDay;
  final bool isWeekView;
  final Function(DateTime) onDaySelected;
  final Function(bool) onViewModeChanged;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback? onTodayPressed;

  const DoctorCalendarHeader({
    super.key,
    required this.focusedDay,
    this.selectedDay,
    required this.isWeekView,
    required this.onDaySelected,
    required this.onViewModeChanged,
    this.onPrevious,
    this.onNext,
    this.onTodayPressed,
  });

  String _formatMonth(DateTime date) {
    final months = [
      'january', 'february', 'march', 'april', 'may', 'june',
      'july', 'august', 'september', 'october', 'november', 'december'
    ];
    return '${months[date.month - 1].tr()} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.chevronLeft),
            onPressed: onPrevious,
            tooltip: 'previous'.tr(),
          ),
          GestureDetector(
            onTap: onTodayPressed,
            child: Text(
              _formatMonth(focusedDay),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.chevronRight),
            onPressed: onNext,
            tooltip: 'next'.tr(),
          ),
          const Spacer(),
          SegmentedButton<bool>(
            segments: [
              ButtonSegment(
                value: false,
                label: Text('day'.tr()),
                icon: Icon(isWeekView ? LucideIcons.square : LucideIcons.layoutList),
              ),
              ButtonSegment(
                value: true,
                label: Text('week'.tr()),
                icon: Icon(isWeekView ? LucideIcons.layoutGrid : LucideIcons.square),
              ),
            ],
            selected: {isWeekView},
            onSelectionChanged: (selected) {
              onViewModeChanged(selected.first);
            },
            style: ButtonStyle(
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: onTodayPressed,
            icon: const Icon(LucideIcons.calendar, size: 18),
            label: Text('today'.tr()),
          ),
        ],
      ),
    );
  }
}