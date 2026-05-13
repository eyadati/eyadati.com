import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons/lucide_icons.dart';

SupabaseClient get _supabase => Supabase.instance.client;

class DoctorAddAppointmentDialog extends StatefulWidget {
  final String clinicId;
  final Map<String, dynamic>? clinic;
  final Function(Map<String, dynamic>)? onAppointmentAdded;

  const DoctorAddAppointmentDialog({
    super.key,
    required this.clinicId,
    this.clinic,
    this.onAppointmentAdded,
  });

  @override
  State<DoctorAddAppointmentDialog> createState() => _DoctorAddAppointmentDialogState();
}

class _DoctorAddAppointmentDialogState extends State<DoctorAddAppointmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isConsultation = false;
  bool _isLoading = false;

  List<Map<String, dynamic>> _doctors = [];
  String? _selectedDoctorId;
  String? _selectedDoctorName;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    try {
      final List<Map<String, dynamic>> doctors = [];
      
      // Add owner (main doctor)
      if (widget.clinic != null) {
        doctors.add({
          'uid': widget.clinicId,
          'doctor_name': widget.clinic!['doctor_name'] ?? widget.clinic!['name'] ?? 'Owner',
        });
      }

      // Load partners
      final partnersResponse = await _supabase
          .from('partners')
          .select()
          .eq('clinic_id', widget.clinicId);

      for (var p in partnersResponse) {
        // Check if partner's clinic is not paused
        final partnerDoc = await _supabase
            .from('clinics')
            .select()
            .eq('uid', p['partner_uid'])
            .maybeSingle();
        
        if (partnerDoc != null && partnerDoc['paused'] != true) {
          doctors.add({
            'uid': p['partner_uid'].toString(),
            'doctor_name': p['partner_name']?.toString() ?? 'Partner',
          });
        }
      }

      if (mounted) {
        setState(() {
          _doctors = doctors;
          if (doctors.isNotEmpty) {
            _selectedDoctorId = doctors.first['uid'];
            _selectedDoctorName = doctors.first['doctor_name'];
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading doctors: $e');
    }
  }

  int get _duration => _isConsultation 
      ? ((widget.clinic?['consultation_duration'] as int?) ?? 30)
      : ((widget.clinic?['duration'] as int?) ?? 30);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.calendarPlus, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      'new_appointment'.tr(),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Patient Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'patient_name'.tr(),
                    prefixIcon: const Icon(LucideIcons.user),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'please_enter_name'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'phone_number'.tr(),
                    prefixIcon: const Icon(LucideIcons.phone),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'please_enter_phone'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Date & Time
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _selectDate,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'date'.tr(),
                            prefixIcon: const Icon(LucideIcons.calendar),
                            border: const OutlineInputBorder(),
                          ),
                          child: Text(
                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: _selectTime,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'time'.tr(),
                            prefixIcon: const Icon(LucideIcons.clock),
                            border: const OutlineInputBorder(),
                          ),
                          child: Text(
                            '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Consultation Toggle
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(
                      value: false,
                      label: Text('appointment'.tr()),
                      icon: const Icon(LucideIcons.calendar),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text('consultation'.tr()),
                      icon: const Icon(LucideIcons.messageCircle),
                    ),
                  ],
                  selected: {_isConsultation},
                  onSelectionChanged: (selected) {
                    setState(() => _isConsultation = selected.first);
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  '${_duration} ${'minutes'.tr()}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Doctor Dropdown
                if (_doctors.length > 1) ...[
                  DropdownButtonFormField<String>(
                    value: _selectedDoctorId,
                    decoration: InputDecoration(
                      labelText: 'select_doctor'.tr(),
                      prefixIcon: const Icon(LucideIcons.userCheck),
                      border: const OutlineInputBorder(),
                    ),
                    items: _doctors.map((doc) {
                      return DropdownMenuItem(
                        value: doc['uid']?.toString(),
                        child: Text(doc['doctor_name']?.toString() ?? ''),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDoctorId = value;
                        _selectedDoctorName = _doctors.firstWhere(
                          (d) => d['uid'] == value,
                          orElse: () => {'doctor_name': 'Unknown'},
                        )['doctor_name']?.toString();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Notes
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'notes'.tr(),
                    prefixIcon: const Icon(LucideIcons.fileText),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('cancel'.tr()),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _isLoading ? null : _saveAppointment,
                      icon: _isLoading 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(LucideIcons.check),
                      label: Text('save'.tr()),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _saveAppointment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final appointmentId = DateTime.now().millisecondsSinceEpoch.toString();

      await _supabase.from('appointments').insert({
        'id': appointmentId,
        'clinic_id': widget.clinicId,
        'patient_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'date': dateTime.toIso8601String(),
        'status': 'upcoming',
        'is_manual': true,
        'is_read': false,
        'is_consultation': _isConsultation,
        'duration': _duration,
        'doctor_id': _selectedDoctorId,
        'doctor_name': _selectedDoctorName,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('appointment_added'.tr())),
        );
      }
    } catch (e) {
      debugPrint('Error adding appointment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('error_adding_appointment'.tr())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}