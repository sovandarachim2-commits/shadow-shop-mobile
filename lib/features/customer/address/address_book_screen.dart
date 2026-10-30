import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shadow_shop_mobile/state/shop_state.dart';
import 'package:shadow_shop_mobile/theme/app_theme.dart';

class AddressBookScreen extends StatefulWidget {
  const AddressBookScreen({
    super.key,
    this.isPicker = false,
    this.selectedAddressId,
  });

  final bool isPicker;
  final int? selectedAddressId;

  @override
  State<AddressBookScreen> createState() => _AddressBookScreenState();
}

class _AddressBookScreenState extends State<AddressBookScreen> {
  static const Color _primaryPink = Color(0xFFEC4899);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textMuted = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFF1F5F9);
  static const Color _bodyBg = Color(0xFFF8FAFC);

  static const List<Map<String, String>> _cambodiaProvinces = [
    {'key': 'phnom_penh', 'label': 'Phnom Penh'},
    {'key': 'kandal', 'label': 'Kandal'},
    {'key': 'takeo', 'label': 'Takeo'},
    {'key': 'kampong_cham', 'label': 'Kampong Cham'},
    {'key': 'siem_reap', 'label': 'Siem Reap'},
    {'key': 'battambang', 'label': 'Battambang'},
    {'key': 'preah_sihanouk', 'label': 'Preah Sihanouk'},
    {'key': 'kampot', 'label': 'Kampot'},
    {'key': 'kampong_speu', 'label': 'Kampong Speu'},
    {'key': 'kampong_chhnang', 'label': 'Kampong Chhnang'},
    {'key': 'kampong_thom', 'label': 'Kampong Thom'},
    {'key': 'prey_veng', 'label': 'Prey Veng'},
    {'key': 'svay_rieng', 'label': 'Svay Rieng'},
    {'key': 'pursat', 'label': 'Pursat'},
    {'key': 'kratie', 'label': 'Kratie'},
    {'key': 'tboung_khmum', 'label': 'Tboung Khmum'},
    {'key': 'banteay_meanchey', 'label': 'Banteay Meanchey'},
    {'key': 'koh_kong', 'label': 'Koh Kong'},
    {'key': 'kep', 'label': 'Kep'},
    {'key': 'pailin', 'label': 'Pailin'},
    {'key': 'oddar_meanchey', 'label': 'Oddar Meanchey'},
    {'key': 'preah_vihear', 'label': 'Preah Vihear'},
    {'key': 'stung_treng', 'label': 'Stung Treng'},
    {'key': 'ratanakiri', 'label': 'Ratanakiri'},
    {'key': 'mondulkiri', 'label': 'Mondulkiri'},
  ];

  bool _loading = false;
  bool _showSearch = false;
  String _searchQuery = '';
  final TextEditingController _listSearchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _listSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      await context.read<ShopState>().loadAddresses();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  String _provinceLabel(String? key) {
    if (key == null || key.isEmpty) return 'Phnom Penh';
    final normalized = key.trim().toLowerCase().replaceAll(' ', '_');
    for (final p in _cambodiaProvinces) {
      if (p['key'] == normalized || p['label']!.toLowerCase() == key.trim().toLowerCase()) {
        return p['label']!;
      }
    }
    return key;
  }

  // Clean Searchable Province Picker BottomSheet
  Future<String?> _selectProvince(BuildContext context, String currentKey) async {
    final searchCtrl = TextEditingController();
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final query = searchCtrl.text.trim().toLowerCase();
          final filtered = _cambodiaProvinces.where((p) {
            if (query.isEmpty) return true;
            return p['label']!.toLowerCase().contains(query) ||
                p['key']!.toLowerCase().contains(query);
          }).toList();

          return SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.72,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Province / City',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: _textDark,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close_rounded, size: 20, color: _textMuted),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search province or city...',
                      hintStyle: const TextStyle(color: _textMuted, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: _primaryPink),
                      suffixIcon: searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18, color: _textMuted),
                              onPressed: () {
                                searchCtrl.clear();
                                setSheetState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: _bodyBg,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _primaryPink, width: 1.5),
                      ),
                    ),
                    onChanged: (_) => setSheetState(() {}),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: Text(
                            'No province found',
                            style: TextStyle(color: _textMuted, fontSize: 14),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: _borderColor),
                          itemBuilder: (context, i) {
                            final prov = filtered[i];
                            final isSelected = prov['key'] == currentKey;
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              tileColor: isSelected ? const Color(0xFFFDF2F8) : Colors.transparent,
                              leading: Icon(
                                Icons.location_city_rounded,
                                size: 20,
                                color: isSelected ? _primaryPink : const Color(0xFF94A3B8),
                              ),
                              title: Text(
                                prov['label']!,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                  color: isSelected ? _primaryPink : _textDark,
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(Icons.check_rounded, color: _primaryPink, size: 20)
                                  : null,
                              onTap: () => Navigator.pop(sheetContext, prov['key']),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showAddressForm([Map<String, dynamic>? initialData]) async {
    final state = context.read<ShopState>();
    final isEditing = initialData != null;
    final int? addressId = isEditing ? int.tryParse('${initialData['id']}') : null;

    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: initialData?['full_name']?.toString() ?? '');
    final phoneCtrl = TextEditingController(text: initialData?['phone']?.toString() ?? '');
    final addressCtrl = TextEditingController(text: initialData?['address_line1']?.toString() ?? '');
    
    String label = initialData?['label']?.toString().toLowerCase() ?? 'home';
    if (!['home', 'work', 'other'].contains(label)) label = 'home';

    String province = 'phnom_penh';
    final rawProv = initialData?['state']?.toString().toLowerCase().replaceAll(' ', '_') ?? '';
    if (_cambodiaProvinces.any((p) => p['key'] == rawProv)) {
      province = rawProv;
    }

    bool isDefault = initialData?['is_default'] == true || (state.savedAddresses.isEmpty && !isEditing);
    bool saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(bottomSheetContext).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEditing ? 'Edit Address' : 'Add New Address',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: _textDark,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(bottomSheetContext),
                        icon: const Icon(Icons.close_rounded, size: 20, color: _textMuted),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Label chips (Home, Work, Other)
                  Row(
                    children: ['home', 'work', 'other'].map((type) {
                      final selected = label == type;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            type[0].toUpperCase() + type.substring(1),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: selected ? Colors.white : _textDark,
                            ),
                          ),
                          selected: selected,
                          selectedColor: _primaryPink,
                          backgroundColor: _bodyBg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: selected ? _primaryPink : _borderColor),
                          ),
                          onSelected: (val) {
                            if (val) setModalState(() => label = type);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // Full name
                  TextFormField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Receiver Name',
                      prefixIcon: const Icon(Icons.person_outline_rounded, size: 20, color: _primaryPink),
                      filled: true,
                      fillColor: _bodyBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter receiver name' : null,
                  ),
                  const SizedBox(height: 12),

                  // Phone
                  TextFormField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: const Icon(Icons.phone_outlined, size: 20, color: _primaryPink),
                      filled: true,
                      fillColor: _bodyBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    validator: (v) => v == null || v.trim().length < 8 ? 'Enter valid phone number' : null,
                  ),
                  const SizedBox(height: 12),

                  // Clean Searchable Province Picker Field (Replacing default dropdown)
                  InkWell(
                    onTap: () async {
                      final picked = await _selectProvince(bottomSheetContext, province);
                      if (picked != null) {
                        setModalState(() => province = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: _bodyBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _borderColor),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.map_outlined, size: 20, color: _primaryPink),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Province / City',
                                  style: TextStyle(fontSize: 11, color: _textMuted, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _provinceLabel(province),
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textDark),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDF2F8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Change', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _primaryPink)),
                                SizedBox(width: 2),
                                Icon(Icons.search_rounded, size: 14, color: _primaryPink),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Address line (street / house)
                  TextFormField(
                    controller: addressCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Street address & House number',
                      hintText: 'e.g. #123, St 456',
                      prefixIcon: const Icon(Icons.home_outlined, size: 20, color: _primaryPink),
                      filled: true,
                      fillColor: _bodyBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Enter street address' : null,
                  ),
                  const SizedBox(height: 12),

                  // Default switch
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Set as default address',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textDark),
                    ),
                    activeThumbColor: _primaryPink,
                    activeTrackColor: _primaryPink.withValues(alpha: 0.5),
                    value: isDefault,
                    onChanged: (val) => setModalState(() => isDefault = val),
                  ),
                  const SizedBox(height: 16),

                  // Submit button
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: saving
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setModalState(() => saving = true);
                              try {
                                final payload = {
                                  'label': label,
                                  'full_name': nameCtrl.text.trim(),
                                  'phone': phoneCtrl.text.trim(),
                                  'address_line1': addressCtrl.text.trim(),
                                  'address_line2': '',
                                  'city': '',
                                  'state': province,
                                  'country': 'Cambodia',
                                  'is_default': isDefault,
                                };
                                if (isEditing && addressId != null) {
                                  await state.updateAddress(addressId, payload);
                                } else {
                                  await state.addAddress(payload);
                                }
                                if (bottomSheetContext.mounted) {
                                  Navigator.pop(bottomSheetContext);
                                }
                              } catch (e) {
                                setModalState(() => saving = false);
                                if (bottomSheetContext.mounted) {
                                  ScaffoldMessenger.of(bottomSheetContext).showSnackBar(
                                    SnackBar(content: Text(friendlyError(e))),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryPink,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: saving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              isEditing ? 'Save Changes' : 'Add Address',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    nameCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
  }

  Future<void> _deleteAddress(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Address?'),
        content: const Text('Are you sure you want to remove this delivery address?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: _textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      try {
        await context.read<ShopState>().deleteAddress(id);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e))));
        }
      }
    }
  }

  Future<void> _setDefault(int id) async {
    try {
      await context.read<ShopState>().setDefaultAddress(id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final allAddresses = context.watch<ShopState>().savedAddresses;
    final filteredAddresses = allAddresses.where((addr) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final name = (addr['full_name']?.toString() ?? '').toLowerCase();
      final phone = (addr['phone']?.toString() ?? '').toLowerCase();
      final street = (addr['address_line1']?.toString() ?? '').toLowerCase();
      final state = (addr['state']?.toString() ?? '').toLowerCase();
      return name.contains(q) || phone.contains(q) || street.contains(q) || state.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: _bodyBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textDark, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isPicker ? 'Select Address' : 'My Addresses',
          style: const TextStyle(color: _textDark, fontSize: 17, fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _showSearch ? Icons.search_off_rounded : Icons.search_rounded,
              color: _showSearch ? _primaryPink : _textDark,
              size: 24,
            ),
            tooltip: 'Search addresses',
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchQuery = '';
                  _listSearchCtrl.clear();
                }
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_rounded, color: _primaryPink, size: 26),
            tooltip: 'Add new address',
            onPressed: () => _showAddressForm(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_showSearch ? 64 : 1),
          child: Column(
            children: [
              if (_showSearch)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: TextField(
                    controller: _listSearchCtrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search name, phone, or address...',
                      hintStyle: const TextStyle(color: _textMuted, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: _primaryPink),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18, color: _textMuted),
                              onPressed: () {
                                _listSearchCtrl.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: _bodyBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _borderColor),
                      ),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  ),
                ),
              Container(color: _borderColor, height: 1),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _primaryPink))
          : allAddresses.isEmpty
              ? _buildEmptyState()
              : filteredAddresses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search_off_rounded, size: 48, color: _textMuted),
                          const SizedBox(height: 12),
                          Text('No address found for "$_searchQuery"',
                              style: const TextStyle(color: _textMuted, fontSize: 14, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: _primaryPink,
                      onRefresh: _refresh,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredAddresses.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final addr = filteredAddresses[index];
                          final int? id = int.tryParse('${addr['id']}');
                          final isDefault = addr['is_default'] == true;
                          final isSelected = widget.isPicker && id != null && id == widget.selectedAddressId;
                          final label = (addr['label']?.toString() ?? 'home').toUpperCase();

                          return InkWell(
                            onTap: widget.isPicker
                                ? () => Navigator.pop(context, addr)
                                : null,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? _primaryPink : (isDefault ? _primaryPink.withValues(alpha: 0.3) : _borderColor),
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: const [
                                  BoxShadow(color: Color(0x060F172A), blurRadius: 10, offset: Offset(0, 4)),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFDF2F8),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          label,
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                            color: _primaryPink,
                                          ),
                                        ),
                                      ),
                                      if (isDefault) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFECFDF5),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.star_rounded, size: 12, color: Color(0xFF10B981)),
                                              SizedBox(width: 2),
                                              Text(
                                                'DEFAULT',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w900,
                                                  color: Color(0xFF10B981),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                      const Spacer(),
                                      // Quick Edit button on each card
                                      InkWell(
                                        onTap: () => _showAddressForm(addr),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF8FAFC),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFFE2E8F0)),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.edit_outlined, size: 14, color: _primaryPink),
                                              SizedBox(width: 4),
                                              Text(
                                                'Edit',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w800,
                                                  color: _textDark,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (widget.isPicker) ...[
                                        const SizedBox(width: 10),
                                        Icon(
                                          isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
                                          color: isSelected ? _primaryPink : Colors.grey.shade300,
                                          size: 22,
                                        ),
                                      ] else ...[
                                        const SizedBox(width: 4),
                                        PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_vert_rounded, size: 20, color: _textMuted),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onSelected: (val) {
                                            if (id == null) return;
                                            if (val == 'edit') {
                                              _showAddressForm(addr);
                                            } else if (val == 'delete') {
                                              _deleteAddress(id);
                                            } else if (val == 'default') {
                                              _setDefault(id);
                                            }
                                          },
                                          itemBuilder: (_) => [
                                            if (!isDefault)
                                              const PopupMenuItem(
                                                value: 'default',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.star_outline_rounded, size: 18, color: Color(0xFFD97706)),
                                                    SizedBox(width: 8),
                                                    Text('Set as default'),
                                                  ],
                                                ),
                                              ),
                                            const PopupMenuItem(
                                              value: 'edit',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit_outlined, size: 18, color: _textDark),
                                                  SizedBox(width: 8),
                                                  Text('Edit'),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red),
                                                  SizedBox(width: 8),
                                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    addr['full_name']?.toString() ?? 'Receiver',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: _textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    addr['phone']?.toString() ?? '',
                                    style: const TextStyle(fontSize: 13, color: _textMuted, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    [
                                      addr['address_line1'],
                                      _provinceLabel(addr['state']?.toString()),
                                    ].where((s) => s != null && '$s'.trim().isNotEmpty).join(', '),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF334155),
                                      fontWeight: FontWeight.w500,
                                      height: 1.3,
                                    ),
                                  ),
                                  if (widget.isPicker && !isDefault && id != null) ...[
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        onPressed: () => _setDefault(id),
                                        icon: const Icon(Icons.star_outline_rounded, size: 14, color: _textMuted),
                                        label: const Text('Set as default', style: TextStyle(fontSize: 11, color: _textMuted)),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: _borderColor)),
        ),
        child: SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () => _showAddressForm(),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Add New Address', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryPink,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFFDF2F8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on_outlined, size: 36, color: _primaryPink),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Addresses Saved',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _textDark),
              ),
              const SizedBox(height: 6),
              const Text(
                'Add your delivery addresses to checkout quickly on future orders.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: _textMuted, height: 1.4),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _showAddressForm(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Address'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryPink,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
}
