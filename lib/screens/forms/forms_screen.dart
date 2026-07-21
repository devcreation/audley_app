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
        bottom: TabBar(controller: _tabCtrl, indicatorColor: AppTheme.goldLight, labelColor: Colors.white, unselectedLabelColor: Colors.white60,
          tabs: const [Tab(text: 'Participant Info'), Tab(text: 'Optional Tours')]),
      ),
      body: TabBarView(controller: _tabCtrl, physics: const NeverScrollableScrollPhysics(), children: [
        _ParticipantForm(onContinue: () => goToTab(1)),
        _ToursForm(onBack: () => goToTab(0)),
      ]),
    );
  }
}

// ─── Participant Information Form (matches website exactly) ─
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
  bool _certify = false;

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
        if (_name.text.isNotEmpty) { _alreadySubmitted = true; _certify = true; }
      }
    } catch (_) {}
    setState(() { _loading = false; _loaded = true; });
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_certify) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please tick the certification checkbox'), backgroundColor: Colors.red));
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    final result = await _api.submitParticipantInfo({
      'full_name': _name.text.trim(), 'job_title': _jobTitle.text.trim(), 'gender': _gender,
      'dob': _dob.text.trim(), 'passport_no': _passportNo.text.trim(),
      'passport_issue_date': _passportIssue.text.trim(), 'passport_expiry_date': _passportExpiry.text.trim(),
      'nationality': _nationality.text.trim(), 'email': _email.text.trim(), 'mobile': _mobile.text.trim(),
      'address': _address.text.trim(),
      'shirt_size': _gender == 'Female' ? _shirtSize : '',
      'kurta_size': _gender == 'Male' ? _kurtaSize : '',
      'kurta_other': _gender == 'Male' && _kurtaSize == 'Other' ? _kurtaOther.text.trim() : '',
      'pajama_size': _gender == 'Male' ? _pajamaSize : '',
      'pajama_other': _gender == 'Male' && _pajamaSize == 'Other' ? _pajamaOther.text.trim() : '',
      'meal_preference': _mealPref, 'dietary_restrictions': _dietRestrictions.text.trim(),
      'medical_info': _medicalInfo.text.trim(), 'special_occasion': _specialOccasion.text.trim(),
      'emergency_contact_name': _emergencyName.text.trim(), 'emergency_contact_phone': _emergencyPhone.text.trim(),
      'accommodations': _accommodations.text.trim(), 'adjustments': _adjustments.text.trim(), 'source': 'app',
    });

    setState(() => _loading = false);
    if (!mounted) return;
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Saved'), backgroundColor: AppTheme.teal));
      widget.onContinue();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Error'), backgroundColor: Colors.red.shade700));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!_loaded) return const Center(child: CircularProgressIndicator());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Title
          const Text('Participant Information Form', style: TextStyle(fontFamily: 'serif', fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),

          if (_alreadySubmitted)
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.teal.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.teal.withValues(alpha: 0.3))),
              child: Row(children: [Icon(Icons.check_circle, color: AppTheme.teal, size: 18), const SizedBox(width: 8),
                Expanded(child: Text('Your details have been submitted. You can update them below.', style: TextStyle(fontSize: 12, color: AppTheme.teal)))]),
            ),

          const SizedBox(height: 8),

          // Q1: Your Name
          _label('Q1: YOUR NAME', true),
          _input(_name, 'Enter your full name', validator: (v) => v!.isEmpty ? 'Required' : null),

          // Q2: Job Title
          _label('Q2: JOB TITLE', true),
          _input(_jobTitle, 'Enter your job title'),

          // Q3: Gender
          _label('Q3: GENDER', true),
          _dropdownField(_gender, ['', 'Male', 'Female'], 'Select', (v) => setState(() { _gender = v ?? ''; _shirtSize = ''; _kurtaSize = ''; _pajamaSize = ''; })),

          // Q4: Date of Birth
          _label('Q4: DATE OF BIRTH', true),
          _input(_dob, 'DD/MM/YYYY', keyboard: TextInputType.datetime),

          // Q5: Passport No.
          _label('Q5: PASSPORT NO.', true),
          _input(_passportNo, 'Enter your passport number'),

          // Q6: Passport Issue Date
          _label('Q6: PASSPORT ISSUE DATE', true),
          _input(_passportIssue, 'DD/MM/YYYY', keyboard: TextInputType.datetime),

          // Q7: Passport Expiry Date
          _label('Q7: PASSPORT EXPIRY DATE', true),
          _input(_passportExpiry, 'DD/MM/YYYY', keyboard: TextInputType.datetime),

          // Q8: Nationality
          _label('Q8: NATIONALITY', true),
          _input(_nationality, 'Enter your nationality'),

          // Q9: Email
          _label('Q9: EMAIL', true),
          _input(_email, 'Enter your email address', keyboard: TextInputType.emailAddress),

          // Q10: Mobile Number
          _label('Q10: MOBILE NUMBER', true),
          _input(_mobile, 'Enter your mobile number', keyboard: TextInputType.phone),

          // Q11: Address
          _label('Q11: ADDRESS', true),
          _input(_address, 'Enter your full address', maxLines: 2),

          // Clothing sizes (gender-based, shown dynamically)
          if (_gender == 'Male') ...[
            _label('Q12: KURTA SIZE', true),
            _dropdownField(_kurtaSize, ['', 'XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL', 'Other'], 'Select size', (v) => setState(() => _kurtaSize = v ?? '')),
            if (_kurtaSize == 'Other') _input(_kurtaOther, 'Please specify your Kurta size'),
            _label('Q13: PAJAMA SIZE', true),
            _dropdownField(_pajamaSize, ['', 'XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL', 'Other'], 'Select size', (v) => setState(() => _pajamaSize = v ?? '')),
            if (_pajamaSize == 'Other') _input(_pajamaOther, 'Please specify your Pajama size'),
          ],
          if (_gender == 'Female') ...[
            _label('Q12: SHIRT SIZE', true),
            _dropdownField(_shirtSize, ['', 'XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL'], 'Select size', (v) => setState(() => _shirtSize = v ?? '')),
          ],

          // Q14: Meal Preference
          _label('Q14: MEAL PREFERENCE', true),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              for (final meal in ['Vegan', 'Pescatarian', 'Vegetarian', 'No Red Meat', 'Non-Vegetarian', 'No Specific Choice'])
                ChoiceChip(
                  label: Text(meal, style: TextStyle(fontSize: 13, color: _mealPref == meal ? Colors.white : (isDark ? Colors.grey[300] : AppTheme.charcoal))),
                  selected: _mealPref == meal,
                  selectedColor: AppTheme.teal,
                  backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: _mealPref == meal ? AppTheme.teal : AppTheme.border)),
                  onSelected: (_) => setState(() => _mealPref = meal),
                ),
            ]),
          ),

          // Q15: Dietary Restrictions
          _label('Q15: DIETARY RESTRICTIONS / ALLERGIES', true),
          _input(_dietRestrictions, 'Enter any dietary restrictions or allergies'),

          // Q16: Medical Information
          _label('Q16: MEDICAL INFORMATION (OPTIONAL)', false),
          _input(_medicalInfo, 'Any medical conditions we should be aware of'),

          // Q17: Special Occasion
          _label('Q17: SPECIAL OCCASION', true),
          _input(_specialOccasion, 'e.g. birthday, anniversary during the trip'),

          // Q18: Emergency Contact
          _label('Q18: EMERGENCY CONTACT', true),
          _sublabel('NAME', true),
          _input(_emergencyName, 'Emergency contact full name'),
          _sublabel('TELEPHONE NUMBER', true),
          _input(_emergencyPhone, 'Emergency contact phone number', keyboard: TextInputType.phone),

          // Q19: Accommodations
          _label('Q19: ACCOMMODATIONS AND ADJUSTMENTS TO YOUR TRIP', true),
          _input(_accommodations, 'Any accommodations or adjustments needed'),

          // Q20: Further Adjustments
          _label('Q20: DO YOU REQUIRE FURTHER ADJUSTMENTS MAKING TO YOUR TRIP? (E.G. DUE TO A MEDICAL REQUIREMENT OR DISABILITY)', true),
          _input(_adjustments, 'Please provide details of any further adjustments required', maxLines: 3),

          // Certification checkbox
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Checkbox(value: _certify, activeColor: AppTheme.teal, onChanged: (v) => setState(() => _certify = v ?? false)),
            Expanded(child: GestureDetector(
              onTap: () => setState(() => _certify = !_certify),
              child: Padding(padding: const EdgeInsets.only(top: 12),
                child: Text('By submitting this form you certify that all details are accurate and understand it is your responsibility to consult, if required, with your GP / Primary Care Physician that you are fit for travel.',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : AppTheme.textMid, height: 1.5))))),
          ]),

          const SizedBox(height: 20),
          SizedBox(height: 50, child: ElevatedButton(
            onPressed: _loading ? null : _saveAndContinue,
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold),
            child: _loading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('SAVE & CONTINUE', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1)),
                    SizedBox(width: 8), Icon(Icons.arrow_forward, size: 18)]),
          )),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _label(String text, bool required) {
    return Padding(padding: const EdgeInsets.only(top: 12, bottom: 6), child: RichText(
      text: TextSpan(style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppTheme.teal), children: [
        TextSpan(text: text),
        if (required) const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
      ])));
  }

  Widget _sublabel(String text, bool required) {
    return Padding(padding: const EdgeInsets.only(bottom: 4), child: RichText(
      text: TextSpan(style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.charcoal), children: [
        TextSpan(text: text),
        if (required) const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
      ])));
  }

  Widget _input(TextEditingController ctrl, String hint, {TextInputType? keyboard, int maxLines = 1, String? Function(String?)? validator}) {
    return Padding(padding: const EdgeInsets.only(bottom: 4), child: TextFormField(
      controller: ctrl, keyboardType: keyboard, maxLines: maxLines, validator: validator,
      decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: AppTheme.textLight, fontSize: 14))));
  }

  Widget _dropdownField(String value, List<String> items, String hint, void Function(String?) onChanged) {
    return Padding(padding: const EdgeInsets.only(bottom: 4), child: DropdownButtonFormField<String>(
      value: items.contains(value) ? value : '',
      hint: Text(hint, style: TextStyle(color: AppTheme.textLight, fontSize: 14)),
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
        _sept12 = d['sept12_choice'] ?? ''; _sept13Yoga = d['sept13_yoga'] ?? ''; _sept14 = d['sept14_choice'] ?? '';
        if (_sept12.isNotEmpty || _sept13Yoga.isNotEmpty || _sept14.isNotEmpty) _alreadySubmitted = true;
      }
    } catch (_) {}
    setState(() { _loading = false; _loaded = true; });
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    final result = await _api.submitOptionalTours({'sept12_choice': _sept12, 'sept13_yoga': _sept13Yoga, 'sept14_choice': _sept14, 'source': 'app'});
    setState(() => _loading = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Saved'), backgroundColor: result['success'] == true ? AppTheme.teal : Colors.red.shade700));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (!_loaded) return const Center(child: CircularProgressIndicator());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(padding: const EdgeInsets.all(16), children: [
      if (_alreadySubmitted)
        Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppTheme.teal.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.teal.withValues(alpha: 0.3))),
          child: Row(children: [Icon(Icons.check_circle, color: AppTheme.teal, size: 18), const SizedBox(width: 8),
            Expanded(child: Text('Your tour choices have been submitted. You can update them below.', style: TextStyle(fontSize: 12, color: AppTheme.teal)))])),

      Text('Select your preferred optional activities. Deadline: 1 August 2026.', style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : AppTheme.textMid)),
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
      Row(children: [
        Expanded(child: SizedBox(height: 50, child: OutlinedButton.icon(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back, size: 18), label: const Text('BACK')))),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: SizedBox(height: 50, child: ElevatedButton(
          onPressed: _loading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold),
          child: _loading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('SAVE & SUBMIT', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1)), SizedBox(width: 8), Icon(Icons.check, size: 18)]),
        ))),
      ]),
      const SizedBox(height: 32),
    ]);
  }

  Widget _sectionCard(String title, String subtitle, List<Widget> children, bool isDark) {
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.w700)),
      Text(subtitle, style: TextStyle(fontSize: 12, color: AppTheme.textMid)), const SizedBox(height: 12), ...children])));
  }

  Widget _radioTile(String group, String value, String label, String emoji) {
    String cv; void Function(String?) oc;
    switch (group) { case 'sept12': cv = _sept12; oc = (v) => setState(() => _sept12 = v ?? ''); break;
      case 'sept13': cv = _sept13Yoga; oc = (v) => setState(() => _sept13Yoga = v ?? ''); break;
      case 'sept14': cv = _sept14; oc = (v) => setState(() => _sept14 = v ?? ''); break;
      default: cv = ''; oc = (_) {}; }
    return RadioListTile<String>(value: value, groupValue: cv, onChanged: oc,
      title: Text('$emoji  $label', style: const TextStyle(fontSize: 14)), dense: true, contentPadding: EdgeInsets.zero, activeColor: AppTheme.teal);
  }
}
