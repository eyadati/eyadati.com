import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:lucide_icons/lucide_icons.dart';

SupabaseClient get _supabase => Supabase.instance.client;

class Partner {
  final String id;
  final String clinicId;
  final String partnerUid;
  final String? partnerName;
  final DateTime? createdAt;

  Partner({
    required this.id,
    required this.clinicId,
    required this.partnerUid,
    this.partnerName,
    this.createdAt,
  });

  factory Partner.fromMap(Map<String, dynamic> data) {
    return Partner(
      id: data['id']?.toString() ?? '',
      clinicId: data['clinic_id']?.toString() ?? '',
      partnerUid: data['partner_uid']?.toString() ?? '',
      partnerName: data['partner_name']?.toString(),
      createdAt: data['created_at'] != null 
          ? DateTime.tryParse(data['created_at'].toString()) 
          : null,
    );
  }
}

class DoctorSidebar extends StatefulWidget {
  final String clinicId;
  final Map<String, dynamic>? clinicData;
  final int selectedIndex;
  final Function(int)? onMenuSelected;

  const DoctorSidebar({
    super.key,
    required this.clinicId,
    this.clinicData,
    this.selectedIndex = 0,
    this.onMenuSelected,
  });

  @override
  State<DoctorSidebar> createState() => _DoctorSidebarState();
}

class _DoctorSidebarState extends State<DoctorSidebar> {
  List<Partner> _partners = [];
  bool _isLoadingPartners = false;

  @override
  void initState() {
    super.initState();
    _loadPartners();
  }

  Future<void> _loadPartners() async {
    setState(() => _isLoadingPartners = true);
    try {
      final response = await _supabase
          .from('partners')
          .select()
          .eq('clinic_id', widget.clinicId);

      final partners = (response as List).map((data) => Partner.fromMap(data)).toList();
      
      if (mounted) {
        setState(() {
          _partners = partners;
          _isLoadingPartners = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading partners: $e');
      if (mounted) {
        setState(() => _isLoadingPartners = false);
      }
    }
  }

  final List<_MenuItem> _menuItems = [
    _MenuItem('dashboard'.tr(), LucideIcons.layoutDashboard, 0),
    _MenuItem('calendar'.tr(), LucideIcons.calendar, 1),
    _MenuItem('appointments'.tr(), LucideIcons.calendarCheck, 2),
    _MenuItem('management'.tr(), LucideIcons.settings, 3),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.primary,
                  child: Text(
                    (widget.clinicData?['doctor_name'] ?? 'D')[0].toString().toUpperCase(),
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.clinicData?['doctor_name'] ?? widget.clinicData?['name'] ?? 'Doctor',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.clinicData?['specialty'] ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer.withAlpha(180),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                ..._menuItems.map((item) => _buildMenuItem(item, theme)),
                const Divider(height: 32),
                _buildMenuItem(
                  _MenuItem('partners'.tr(), LucideIcons.userPlus, 4),
                  theme,
                  showDialog: true,
                ),
              ],
            ),
          ),
          
          // Partners count
          if (_partners.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: theme.dividerColor),
                ),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.users, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    '${_partners.length} ${'partners'.tr()}',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(_MenuItem item, ThemeData theme, {bool showDialog = false}) {
    final isSelected = widget.selectedIndex == item.index;
    
    return ListTile(
      leading: Icon(
        item.icon,
        color: isSelected ? theme.colorScheme.primary : null,
      ),
      title: Text(
        item.title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : null,
          color: isSelected ? theme.colorScheme.primary : null,
        ),
      ),
      selected: isSelected,
      selectedTileColor: theme.colorScheme.primaryContainer.withAlpha(100),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: showDialog 
          ? () => _showPartnersDialog()
          : () => widget.onMenuSelected?.call(item.index),
    );
  }

  void _showPartnersDialog() {
    showDialog(
      context: context,
      builder: (context) => _PartnersDialog(
        clinicId: widget.clinicId,
        partners: _partners,
        onPartnerAdded: _loadPartners,
        onPartnerRemoved: _loadPartners,
      ),
    );
  }
}

class _MenuItem {
  final String title;
  final IconData icon;
  final int index;

  _MenuItem(this.title, this.icon, this.index);
}

class _PartnersDialog extends StatefulWidget {
  final String clinicId;
  final List<Partner> partners;
  final VoidCallback? onPartnerAdded;
  final VoidCallback? onPartnerRemoved;

  const _PartnersDialog({
    required this.clinicId,
    required this.partners,
    this.onPartnerAdded,
    this.onPartnerRemoved,
  });

  @override
  State<_PartnersDialog> createState() => _PartnersDialogState();
}

class _PartnersDialogState extends State<_PartnersDialog> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(LucideIcons.userPlus, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'partners'.tr(),
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'partner_email'.tr(),
                      hintText: 'enter_partner_email'.tr(),
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _addPartner,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('add'.tr()),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            if (widget.partners.isEmpty)
              Center(
                child: Text(
                  'no_partners'.tr(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(150),
                  ),
                ),
              )
            else
              ...widget.partners.map((partner) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    (partner.partnerName ?? 'P')[0].toUpperCase(),
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ),
                title: Text(partner.partnerName ?? 'partner'.tr()),
                subtitle: Text(partner.partnerUid.substring(0, 8) + '...'),
                trailing: IconButton(
                  icon: const Icon(LucideIcons.trash2, size: 18),
                  onPressed: () => _removePartner(partner.id),
                ),
              )),
          ],
        ),
      ),
    );
  }

  Future<void> _addPartner() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'please_enter_email'.tr());
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Find user by email in clinics table
      final response = await _supabase
          .from('clinics')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (response == null) {
        setState(() {
          _error = 'clinic_not_found'.tr();
          _isLoading = false;
        });
        return;
      }

      final partnerUid = response['uid'] as String;
      final partnerName = response['doctor_name'] as String? ?? response['name'] as String?;

      await _supabase.from('partners').insert({
        'clinic_id': widget.clinicId,
        'partner_uid': partnerUid,
        'partner_name': partnerName,
      });

      _emailController.clear();
      widget.onPartnerAdded?.call();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Error adding partner: $e');
      setState(() {
        _error = 'error_adding_partner'.tr();
        _isLoading = false;
      });
    }
  }

  Future<void> _removePartner(String partnerId) async {
    try {
      await _supabase
          .from('partners')
          .delete()
          .eq('id', partnerId);
      widget.onPartnerRemoved?.call();
    } catch (e) {
      debugPrint('Error removing partner: $e');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}