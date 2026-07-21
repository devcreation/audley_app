import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../data/api_client.dart';

class FormsScreen extends ConsumerStatefulWidget {
  const FormsScreen({super.key});
  @override
  ConsumerState<FormsScreen> createState() => _FormsScreenState();
}

class _FormsScreenState extends ConsumerState<FormsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 2, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  void goToTab(int index) { _tabCtrl.animateTo(index); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppTheme.goldLight,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [Tab(text: 'Participant Info'), Tab(text: 'Optional Tours')],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _ParticipantForm(onContinue: () => goToTab(1)),
          _ToursForm(onBack: () => goToTab(0)),
        ],
      ),
    );
  }
}

// ─── Participant Information Form ───────────────────────────
class _ParticipantForm extends StatefulWidget {
  final VoidCallback onContinue;
  const _ParticipantForm({required this.onContinue});
  @override
  State<_ParticipantForm> createState() => _ParticipantFormState();
}

class _ParticipantFormState extends State<_ParticipantForm> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _api = ApiClient();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _loaded = false;
  bool _alreadySubmitted = false;

  final _name = TextEditingController();
  final _jobTitle = TextEditingController();
  final _dob = TextEditingController();
  final _passportNo = TextEditingController();
  final _passportIssue = TextEditingController();
  final _passportExpiry = TextEditingController();
  final _nationality = TextEditingController();
  final _email = TextEditingController();
  final _mobile = TextEditingController();
  final _address = TextEditingController();
  final _dietRestrictions = TextEditingController();
  final _medicalInfo = TextEditingController();
  final _specialOccasion = TextEditingController();
  final _emergencyName = TextEditingController();
  final _emergencyPhone = TextEditingController();
  final _accommodations = TextEditingController();
  final _adjustments = TextEditingController();
  final _kurtaOther = TextEditingController();
  final _pajamaOther = TextEditingController();

  String _gender = '';
  String _shirtSize = '';
  String _kurtaSize = '';
  String _pajamaSize = '';
  String _mealPref = '';

  @override
  void initState() { super.initState(); _loadExisting(); }

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    try {
      final result = await _api.getParticipantInfo();
      if (result['success'] == true && result['data'] != null) {
        final d = result['data'];
        _name.text = d['full_name'] ?? '';
        _jobTitle.text = d['job_title'] ?? '';
        _gender = d['gender'] ?? '';
        _dob.text = d['dob'] ?? '';
        _passportNo.text = d['passport_no'] ?? '';
        _passportIssue.text = d['passport_issue_date'] ?? '';
        _passportExpiry.text = d['passport_expiry_date'] ?? '';
        _nationality.text = d['nationality'] ?? '';
        _email.text = d['email'] ?? '';
        _mobile.text = d['mobile'] ?? '';
        _address.text = d['address'] ?? '';
        _shirtSize = d['shirt_size'] ?? '';
        _kurtaSize = d['kurta_size'] ?? '';
        _kurtaOther.text = d['kurta_other'] ?? '';
        _pajamaSize = d['pajama_size'] ?? '';
        _pajamaOther.text = d['pajama_other'] ?? '';
        _mealPref = d['meal_preference'] ?? '';
        _dietRestrictions.text = d['dietary_restrictions'] ?? '';
        _medicalInfo.text = d['medical_info'] ?? '';
        _specialOccasion.text = d['special_occasion'] ?? '';
        _emergencyName.text = d['emergency_contact_name'] ?? '';
        _emergencyPhone.text = d['emergency_contact_phone'] ?? '';
        _accommodations.text = d['accommodations'] ?? '';
        _adjustments.text = d['adjustments'] ?? '';
        if (_name.text.isNotEmpty) _alreadySubmitted = true;
      }
    } catch (_) {}
    setState(() { _loading = false; _loaded = true; });
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    final result = await _api.submitParticipantInfo({
      'full_name': _name.text.trim(),
      'job_title': _jobTitle.text.trim(),
      'gender': _gender,
      'dob': _dob.text.trim(),
      'passport_no': _passportNo.text.trim(),
      'passport_issue_date': _passportIssue.text.trim(),
      'passport_expiry_date': _passportExpiry.text.trim(),
      'nationality': _nationality.text.trim(),
      'email': _email.text.trim(),
      'mobile': _mobile.text.trim(),
      'address': _address.text.trim(),
      'shirt_size': _gender == 'Female' ? _shirtSize : '',
      'kurta_size': _gender == 'Male' ? _kurtaSize : '',
      'kurta_other': _gender == 'Male' && _kurtaSize == 'Other' ? _kurtaOther.text.trim() : '',
      'pajama_size': _gender == 'Male' ? _pajamaSize : '',
      'pajama_other': _gender == 'Male' && _pajamaSize == 'Other' ? _pajamaOther.text.trim() : '',
      'meal_preference': _mealPref,
      'dietary_restrictions': _dietRestrictions.text.trim(),
      'medical_info': _medicalInfo.text.trim(),
      'special_occasion': _specialOccasion.text.trim(),
      'emergency_contact_name': _emergencyName.text.trim(),
      'emergency_contact_phone': _emergencyPhone.text.trim(),
      'accommodations': _accommodations.text.trim(),
      'adjustments': _adjustments.text.trim(),
      'source': 'app',
    });

    setState(() => _loading = false);
    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Saved'), backgroundColor: AppTheme.teal));
      widget.onContinue();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Error'), backgroundColor: Colors.red.shade700));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!_loaded) return const Center(child: CircularProgressIndicator());

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_alreadySubmitted)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.teal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.teal.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                Icon(Icons.check_circle, color: AppTheme.teal, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text('Your details have been submitted. You can update them below.',
                    style: TextStyle(fontSize: 13, color: AppTheme.teal))),
              ]),
            ),

          _field('Full Name *', _name, validator: (v) => v!.isEmpty ? 'Required' : null),
          _field('Job Title', _jobTitle),
          _dropdown('Gender', _gender, ['', 'Male', 'Female'], (v) => setState(() { _gender = v ?? ''; _shirtSize = ''; _kurtaSize = ''; _pajamaSize = ''; })),
          _field('Date of Birth (DD/MM/YYYY)', _dob, keyboard: TextInputType.datetime),
          _field('Passport Number', _passportNo),
          _field('Passport Issue Date (DD/MM/YYYY)', _passportIssue, keyboard: TextInputType.datetime),
          _field('Passport Expiry Date (DD/MM/YYYY)', _passportExpiry, keyboard: TextInputType.datetime),
          _field('Nationality', _nationality),
          _field('Email', _email, keyboard: TextInputType.emailAddress),
          _field('Mobile Number', _mobile, keyboard: TextInputType.phone),
          _field('Address', _address, maxLines: 2),

          // Clothing - gender based
          if (_gender == 'Male') ...[
            _dropdown('Kurta Size', _kurtaSize, ['', 'XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL', 'Other'], (v) => setState(() => _kurtaSize = v ?? '')),
            if (_kurtaSize == 'Other') _field('Please specify Kurta size', _kurtaOther),
            _dropdown('Pajama Size', _pajamaSize, ['', 'XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL', 'Other'], (v) => setState(() => _pajamaSize = v ?? '')),
            if (_pajamaSize == 'Other') _field('Please specify Pajama size', _pajamaOther),
          ],
          if (_gender == 'Female')
            _dropdown('Shirt Size', _shirtSize, ['', 'XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL'], (v) => setState(() => _shirtSize = v ?? '')),

          _dropdown('Meal Preference', _mealPref, ['', 'Vegan', 'Pescatarian', 'Vegetarian', 'No Red Meat', 'Non-Vegetarian', 'No Specific Choice'], (v) => setState(() => _mealPref = v ?? '')),
          _field('Dietary Restrictions / Allergies', _dietRestrictions, maxLines: 2),
          _field('Medical Conditions / Medications', _medicalInfo, maxLines: 2),
          _field('Special Occasion (birthday, anniversary)', _specialOccasion),
          _field('Emergency Contact Name', _emergencyName),
          _field('Emergency Contact Phone', _emergencyPhone, keyboard: TextInputType.phone),
          _field('Accommodation Needs', _accommodations, maxLines: 2),
          _field('Any Adjustments Required', _adjustments, maxLines: 2),

          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _loading ? null : _saveAndContinue,
              icon: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Icon(Icons.arrow_forward, size: 20),
              label: Text(_loading ? 'Saving...' : 'SAVE AND CONTINUE'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {TextInputType? keyboard, int maxLines = 1, String? Function(String?)? validator}) {
    return Padding(padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(controller: ctrl, keyboardType: keyboard, maxLines: maxLines, decoration: InputDecoration(labelText: label), validator: validator));
  }

  Widget _dropdown(String label, String value, List<String> items, void Function(String?) onChanged) {
    return Padding(padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: items.contains(value) ? value : '',
        decoration: InputDecoration(labelText: label),
        items: items.map((s) => DropdownMenuItem(value: s, child: Text(s.isEmpty ? '— Select —' : s))).toList(),
        onChanged: onChanged));
  }
}

// ─── Optional Tours Form ────────────────────────────────────
class _ToursForm extends StatefulWidget {
  final VoidCallback onBack;
  const _ToursForm({required this.onBack});
  @override
  State<_ToursForm> createState() => _ToursFormState();
}

class _ToursFormState extends State<_ToursForm> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _api = ApiClient();
  bool _loading = false;
  bool _loaded = false;
  bool _alreadySubmitted = false;

  String _sept12 = '';
  String _sept13Yoga = '';
  String _sept14 = '';

  @override
  void initState() { super.initState(); _loadExisting(); }

  Future<void> _loadExisting() async {
    setState(() => _loading = true);
    try {
      final result = await _api.getOptionalTours();
      if (result['success'] == true && result['data'] != null) {
        final d = result['data'];
        _sept12 = d['sept12_choice'] ?? '';
        _sept13Yoga = d['sept13_yoga'] ?? '';
        _sept14 = d['sept14_choice'] ?? '';
        if (_sept12.isNotEmpty || _sept13Yoga.isNotEmpty || _sept14.isNotEmpty) _alreadySubmitted = true;
      }
    } catch (_) {}
    setState(() { _loading = false; _loaded = true; });
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    final result = await _api.submitOptionalTours({
      'sept12_choice': _sept12, 'sept13_yoga': _sept13Yoga, 'sept14_choice': _sept14, 'source': 'app',
    });
    setState(() => _loading = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result['message'] ?? 'Saved'),
      backgroundColor: result['success'] == true ? AppTheme.teal : Colors.red.shade700));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!_loaded) return const Center(child: CircularProgressIndicator());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_alreadySubmitted)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.teal.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.teal.withValues(alpha: 0.3)),
            ),
            child: Row(children: [
              Icon(Icons.check_circle, color: AppTheme.teal, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text('Your tour choices have been submitted. You can update them below.',
                  style: TextStyle(fontSize: 13, color: AppTheme.teal))),
            ]),
          ),

        Text('Select your preferred optional activities. Deadline: 1 August 2026.',
            style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : AppTheme.textMid)),
        const SizedBox(height: 20),

        _sectionCard('Saturday, 12 September', 'Afternoon (1400–1600)', [
          _radioTile('sept12', 'orientation', 'Pink Rickshaw Orientation Tour + Observatory', '🛺'),
          _radioTile('sept12', 'heritage_walk', 'Old Jaipur Heritage, Art & Street Food Walk', '🚶'),
          _radioTile('sept12', 'block_printing', 'Hands-on Block Printing Workshop', '🎨'),
          _radioTile('sept12', 'none', 'No tour — free time', '😌'),
        ], isDark),
        const SizedBox(height: 16),

        _sectionCard('Sunday, 13 September', 'Morning (0630–0715)', [
          _radioTile('sept13', 'yes', 'Yes, I\'ll join the Yoga session', '🧘'),
          _radioTile('sept13', 'no', 'No, I\'ll skip this one', '😴'),
        ], isDark),
        const SizedBox(height: 16),

        _sectionCard('Monday, 14 September', 'Morning', [
          _radioTile('sept14', 'safari', 'Jhalana Safari (0500–0830)', '🐆'),
          _radioTile('sept14', 'cycling', 'Jaipur Cycling Tour (0630–0830)', '🚴'),
          _radioTile('sept14', 'flowers', 'Great Exotic Flower Tour (0715–1000)', '🌺'),
          _radioTile('sept14', 'rickshaw', 'Pink Rickshaw + Observatory (0800–1000)', '🛺'),
          _radioTile('sept14', 'none', 'No tour — sleep in', '😌'),
        ], isDark),

        const SizedBox(height: 28),
        // Two buttons: Back and Save & Submit
        Row(children: [
          Expanded(
            child: SizedBox(height: 50, child: OutlinedButton.icon(
              onPressed: widget.onBack,
              icon: const Icon(Icons.arrow_back, size: 20),
              label: const Text('BACK'),
            )),
          ),
          const SizedBox(width: 12),
          Expanded(flex: 2,
            child: SizedBox(height: 50, child: ElevatedButton.icon(
              onPressed: _loading ? null : _submit,
              icon: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Icon(Icons.check, size: 20),
              label: Text(_loading ? 'Saving...' : 'SAVE & SUBMIT'),
            )),
          ),
        ]),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _sectionCard(String title, String subtitle, List<Widget> children, bool isDark) {
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.w700)),
      Text(subtitle, style: TextStyle(fontSize: 12, color: AppTheme.textMid)),
      const SizedBox(height: 12), ...children,
    ])));
  }

  Widget _radioTile(String group, String value, String label, String emoji) {
    String currentValue; void Function(String?) onChanged;
    switch (group) {
      case 'sept12': currentValue = _sept12; onChanged = (v) => setState(() => _sept12 = v ?? ''); break;
      case 'sept13': currentValue = _sept13Yoga; onChanged = (v) => setState(() => _sept13Yoga = v ?? ''); break;
      case 'sept14': currentValue = _sept14; onChanged = (v) => setState(() => _sept14 = v ?? ''); break;
      default: currentValue = ''; onChanged = (_) {};
    }
    return RadioListTile<String>(value: value, groupValue: currentValue, onChanged: onChanged,
      title: Text('$emoji  $label', style: const TextStyle(fontSize: 14)),
      dense: true, contentPadding: EdgeInsets.zero, activeColor: AppTheme.teal);
  }
}
