import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../data/api_client.dart';

/// Matches website behavior exactly:
/// - Both submitted → confirmation panel, both tabs locked
/// - Only pinfo submitted → jump to tours tab
/// - Neither → start on pinfo tab
/// - "Save & Continue" saves pinfo, moves to tours
/// - "Save & Submit" saves both, shows confirmation, locks tabs

class FormsScreen extends ConsumerStatefulWidget {
  const FormsScreen({super.key});
  @override
  ConsumerState<FormsScreen> createState() => _FormsScreenState();
}

enum FormState_ { loading, neitherSubmitted, pinfoOnly, toursOnly, bothSubmitted }

class _FormsScreenState extends ConsumerState<FormsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _api = ApiClient();
  FormState_ _formState = FormState_.loading;
  Map<String, dynamic>? _pinfoData;
  Map<String, dynamic>? _toursData;
  Map<String, dynamic> _avail = {};

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 3, vsync: this); _loadAll(); }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _loadAll() async {
    setState(() => _formState = FormState_.loading);
    try {
      final results = await Future.wait([_api.getParticipantInfo(), _api.getOptionalTours(), _api.getTourAvailability()]);
      final pRes = results[0]; final tRes = results[1]; final aRes = results[2];
      bool pFilled = false, tFilled = false;
      if (pRes['success'] == true && pRes['data'] != null && (pRes['data']['full_name'] ?? '').toString().isNotEmpty) {
        _pinfoData = pRes['data']; pFilled = true;
      }
      if (tRes['success'] == true && tRes['data'] != null) {
        final d = tRes['data'];
        if ((d['sept12_choice'] ?? '').toString().isNotEmpty || (d['sept13_yoga'] ?? '').toString().isNotEmpty || (d['sept14_choice'] ?? '').toString().isNotEmpty) {
          _toursData = d; tFilled = true;
        }
      }
      if (aRes['success'] == true && aRes['data'] != null) _avail = Map<String, dynamic>.from(aRes['data']);

      if (pFilled && tFilled) { _formState = FormState_.bothSubmitted; _tabCtrl.animateTo(2); }
      else if (pFilled && !tFilled) { _formState = FormState_.pinfoOnly; _tabCtrl.animateTo(1); }
      else if (!pFilled && tFilled) { _formState = FormState_.toursOnly; _tabCtrl.animateTo(0); }
      else { _formState = FormState_.neitherSubmitted; _tabCtrl.animateTo(0); }
    } catch (_) { _formState = FormState_.neitherSubmitted; }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final locked0 = _formState == FormState_.bothSubmitted;
    final locked1 = _formState == FormState_.bothSubmitted || _formState == FormState_.toursOnly;
    return Scaffold(
      appBar: AppBar(title: const Text('Registration'),
        bottom: TabBar(controller: _tabCtrl, indicatorColor: AppTheme.goldLight, labelColor: Colors.white, unselectedLabelColor: Colors.white60,
          onTap: (i) { if ((i == 0 && locked0) || (i == 1 && locked1) || (i == 2 && _formState != FormState_.bothSubmitted)) _tabCtrl.animateTo(_tabCtrl.previousIndex); },
          tabs: [
            Tab(child: Opacity(opacity: locked0 ? 0.4 : 1, child: const Text('Participant Info'))),
            Tab(child: Opacity(opacity: locked1 ? 0.4 : 1, child: const Text('Optional Tours'))),
            Tab(child: Opacity(opacity: _formState == FormState_.bothSubmitted ? 1 : 0.4, child: const Text('Confirmation'))),
          ])),
      body: _formState == FormState_.loading
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(controller: _tabCtrl, physics: const NeverScrollableScrollPhysics(), children: [
            locked0 ? _lockedPanel('Participant Info') : _ParticipantForm(data: _pinfoData, onContinue: _onPinfoContinue),
            locked1 ? _lockedToursPanel() : _ToursForm(data: _toursData, avail: _avail, onBack: () => _tabCtrl.animateTo(0), onSubmit: _onToursSubmit),
            _confirmationPanel(),
          ]),
    );
  }

  Widget _lockedPanel(String title) {
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 52, height: 52, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.teal.withOpacity(0.1)),
        child: const Icon(Icons.check, color: AppTheme.teal, size: 28)),
      const SizedBox(height: 16),
      Text('$title submitted', style: const TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text('Your details have been received.', style: TextStyle(fontSize: 14, color: AppTheme.textMid), textAlign: TextAlign.center),
    ])));
  }

  Widget _lockedToursPanel() {
    if (_formState == FormState_.toursOnly) {
      return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.amber.withOpacity(0.15)),
          child: const Icon(Icons.check, color: Colors.amber, size: 24)),
        const SizedBox(height: 16),
        const Text('Your Optional Tours have already been submitted', style: TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.amber), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text('Please complete your Participation Info to finalize your registration.', style: TextStyle(fontSize: 14, color: AppTheme.textMid), textAlign: TextAlign.center),
      ])));
    }
    return _lockedPanel('Optional Tours');
  }

  Widget _confirmationPanel() {
    if (_formState != FormState_.bothSubmitted) {
      return Center(child: Text('Complete both forms to see confirmation.', style: TextStyle(color: AppTheme.textMid)));
    }
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 52, height: 52, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.gold.withOpacity(0.1)),
        child: Icon(Icons.check, color: AppTheme.gold, size: 28)),
      const SizedBox(height: 16),
      const Text('Your details have been submitted', style: TextStyle(fontFamily: 'serif', fontSize: 20, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      Text('Thank you! Your participant information and optional tour selections have been received.\n\nIf you need to make any changes, please contact us at audleytopperformers@distantfrontiers.in',
        style: TextStyle(fontSize: 14, color: AppTheme.textMid, height: 1.6), textAlign: TextAlign.center),
    ])));
  }

  void _onPinfoContinue() { setState(() { _formState = FormState_.pinfoOnly; }); _tabCtrl.animateTo(1); }

  Future<void> _onToursSubmit(Map<String, dynamic> toursFields) async {
    setState(() { _formState = FormState_.bothSubmitted; });
    _tabCtrl.animateTo(2);
  }
}

// ─── Participant Info Form ──────────────────────────────────
class _ParticipantForm extends StatefulWidget {
  final Map<String, dynamic>? data;
  final VoidCallback onContinue;
  const _ParticipantForm({this.data, required this.onContinue});
  @override
  State<_ParticipantForm> createState() => _ParticipantFormState();
}

class _ParticipantFormState extends State<_ParticipantForm> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final _api = ApiClient(); final _formKey = GlobalKey<FormState>();
  bool _loading = false, _certify = false;
  final _name = TextEditingController(); final _jobTitle = TextEditingController();
  final _dob = TextEditingController(); final _passportNo = TextEditingController();
  final _passportIssue = TextEditingController(); final _passportExpiry = TextEditingController();
  final _nationality = TextEditingController(); final _email = TextEditingController();
  final _mobile = TextEditingController(); final _address = TextEditingController();
  final _dietRestrictions = TextEditingController(); final _medicalInfo = TextEditingController();
  final _specialOccasion = TextEditingController(); final _emergencyName = TextEditingController();
  final _emergencyPhone = TextEditingController(); final _accommodations = TextEditingController();
  final _adjustments = TextEditingController(); final _kurtaOther = TextEditingController(); final _pajamaOther = TextEditingController();
  String _gender = '', _shirtSize = '', _kurtaSize = '', _pajamaSize = '', _mealPref = '';

  @override
  void initState() { super.initState(); _prefill(); }

  void _prefill() {
    final d = widget.data;
    if (d == null) return;
    _name.text = d['full_name'] ?? ''; _jobTitle.text = d['job_title'] ?? ''; _gender = d['gender'] ?? '';
    _dob.text = d['dob'] ?? ''; _passportNo.text = d['passport_no'] ?? '';
    _passportIssue.text = d['passport_issue_date'] ?? ''; _passportExpiry.text = d['passport_expiry_date'] ?? '';
    _nationality.text = d['nationality'] ?? ''; _email.text = d['email'] ?? ''; _mobile.text = d['mobile'] ?? '';
    _address.text = d['address'] ?? ''; _shirtSize = d['shirt_size'] ?? '';
    _kurtaSize = d['kurta_size'] ?? ''; _kurtaOther.text = d['kurta_other'] ?? '';
    _pajamaSize = d['pajama_size'] ?? ''; _pajamaOther.text = d['pajama_other'] ?? '';
    _mealPref = d['meal_preference'] ?? ''; _dietRestrictions.text = d['dietary_restrictions'] ?? '';
    _medicalInfo.text = d['medical_info'] ?? ''; _specialOccasion.text = d['special_occasion'] ?? '';
    _emergencyName.text = d['emergency_contact_name'] ?? ''; _emergencyPhone.text = d['emergency_contact_phone'] ?? '';
    _accommodations.text = d['accommodations'] ?? ''; _adjustments.text = d['adjustments'] ?? '';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_certify) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please tick the certification checkbox'), backgroundColor: Colors.red)); return; }
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    final result = await _api.submitParticipantInfo({
      'full_name': _name.text.trim(), 'job_title': _jobTitle.text.trim(), 'gender': _gender, 'dob': _dob.text.trim(),
      'passport_no': _passportNo.text.trim(), 'passport_issue_date': _passportIssue.text.trim(), 'passport_expiry_date': _passportExpiry.text.trim(),
      'nationality': _nationality.text.trim(), 'email': _email.text.trim(), 'mobile': _mobile.text.trim(), 'address': _address.text.trim(),
      'shirt_size': _gender == 'Female' ? _shirtSize : '', 'kurta_size': _gender == 'Male' ? _kurtaSize : '',
      'kurta_other': _gender == 'Male' && _kurtaSize == 'Other' ? _kurtaOther.text.trim() : '',
      'pajama_size': _gender == 'Male' ? _pajamaSize : '', 'pajama_other': _gender == 'Male' && _pajamaSize == 'Other' ? _pajamaOther.text.trim() : '',
      'meal_preference': _mealPref, 'dietary_restrictions': _dietRestrictions.text.trim(), 'medical_info': _medicalInfo.text.trim(),
      'special_occasion': _specialOccasion.text.trim(), 'emergency_contact_name': _emergencyName.text.trim(),
      'emergency_contact_phone': _emergencyPhone.text.trim(), 'accommodations': _accommodations.text.trim(), 'adjustments': _adjustments.text.trim(), 'source': 'app',
    });
    setState(() => _loading = false);
    if (!mounted) return;
    if (result['success'] == true) { widget.onContinue(); }
    else { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Error'), backgroundColor: Colors.red.shade700)); }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Name, email, mobile are readonly (pre-filled from registration, matching website)
    final nameRO = _name.text.isNotEmpty && widget.data != null;
    final emailRO = _email.text.isNotEmpty && widget.data != null;
    final mobileRO = _mobile.text.isNotEmpty && widget.data != null;

    return Form(key: _formKey, child: ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Participant Information Form', style: TextStyle(fontFamily: 'serif', fontSize: 20, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      _lbl('Q1: YOUR NAME', true), _inp(_name, 'Enter your full name', readOnly: nameRO, validator: (v) => v!.isEmpty ? 'Required' : null),
      _lbl('Q2: JOB TITLE', true), _inp(_jobTitle, 'Enter your job title', readOnly: nameRO),
      _lbl('Q3: GENDER', true), _dd(_gender, ['', 'Male', 'Female'], 'Select', (v) => setState(() { _gender = v ?? ''; })),
      _lbl('Q4: DATE OF BIRTH', true), _inp(_dob, 'DD/MM/YYYY', keyboard: TextInputType.datetime),
      _lbl('Q5: PASSPORT NO.', true), _inp(_passportNo, 'Enter your passport number'),
      _lbl('Q6: PASSPORT ISSUE DATE', true), _inp(_passportIssue, 'DD/MM/YYYY', keyboard: TextInputType.datetime),
      _lbl('Q7: PASSPORT EXPIRY DATE', true), _inp(_passportExpiry, 'DD/MM/YYYY', keyboard: TextInputType.datetime),
      _lbl('Q8: NATIONALITY', true), _inp(_nationality, 'Enter your nationality'),
      _lbl('Q9: EMAIL', true), _inp(_email, 'Enter your email', readOnly: emailRO, keyboard: TextInputType.emailAddress),
      _lbl('Q10: MOBILE NUMBER', true), _inp(_mobile, 'Enter your mobile number', readOnly: mobileRO, keyboard: TextInputType.phone),
      _lbl('Q11: ADDRESS', true), _inp(_address, 'Enter your full address', maxLines: 2),
      if (_gender == 'Male') ...[
        _lbl('Q12: KURTA SIZE', true), _dd(_kurtaSize, ['', 'S', 'M', 'L', 'XL', 'XXL', '3XL', 'Other'], 'Select', (v) => setState(() => _kurtaSize = v ?? '')),
        if (_kurtaSize == 'Other') _inp(_kurtaOther, 'Specify'),
        _lbl('Q13: PAJAMA SIZE', true), _dd(_pajamaSize, ['', 'S', 'M', 'L', 'XL', 'XXL', 'Other'], 'Select', (v) => setState(() => _pajamaSize = v ?? '')),
        if (_pajamaSize == 'Other') _inp(_pajamaOther, 'Specify'),
      ],
      if (_gender == 'Female') ...[_lbl('Q12: SHIRT SIZE (INCHES)', true), _inp(TextEditingController(text: _shirtSize), 'e.g. 36 inches')],
      _lbl('Q14: MEAL PREFERENCE', true),
      Padding(padding: const EdgeInsets.only(bottom: 16), child: Wrap(spacing: 8, runSpacing: 8, children: [
        for (final m in ['Vegan', 'Pescatarian', 'Vegetarian', 'No Red Meat', 'Non-Vegetarian', 'No Specific Choice'])
          ChoiceChip(label: Text(m, style: TextStyle(fontSize: 13, color: _mealPref == m ? Colors.white : (isDark ? Colors.grey[300] : AppTheme.charcoal))),
            selected: _mealPref == m, selectedColor: AppTheme.teal, backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: _mealPref == m ? AppTheme.teal : AppTheme.border)),
            onSelected: (_) => setState(() => _mealPref = m)),
      ])),
      _lbl('Q15: DIETARY RESTRICTIONS / ALLERGIES', true), _inp(_dietRestrictions, 'Enter any dietary restrictions or allergies'),
      _lbl('Q16: MEDICAL INFORMATION (OPTIONAL)', false), _inp(_medicalInfo, 'Any medical conditions we should be aware of'),
      _lbl('Q17: SPECIAL OCCASION', true), _inp(_specialOccasion, 'e.g. birthday, anniversary during the trip'),
      _lbl('Q18: EMERGENCY CONTACT', true), _slbl('NAME', true), _inp(_emergencyName, 'Emergency contact full name'),
      _slbl('TELEPHONE NUMBER', true), _inp(_emergencyPhone, 'Emergency contact phone number', keyboard: TextInputType.phone),
      _lbl('Q19: ACCOMMODATIONS AND ADJUSTMENTS', true), _inp(_accommodations, 'Any accommodations or adjustments needed'),
      _lbl('Q20: FURTHER ADJUSTMENTS?', true), _inp(_adjustments, 'Details of any further adjustments required', maxLines: 3),
      const SizedBox(height: 8),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Checkbox(value: _certify, activeColor: AppTheme.teal, onChanged: (v) => setState(() => _certify = v ?? false)),
        Expanded(child: GestureDetector(onTap: () => setState(() => _certify = !_certify),
          child: Padding(padding: const EdgeInsets.only(top: 12), child: Text('By submitting this form you certify that all details are accurate and understand it is your responsibility to consult, if required, with your GP / Primary Care Physician that you are fit for travel.',
            style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : AppTheme.textMid, height: 1.5))))),
      ]),
      const SizedBox(height: 20),
      SizedBox(height: 50, child: ElevatedButton(onPressed: _loading ? null : _save, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold),
        child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
          : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('SAVE & CONTINUE', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1)), SizedBox(width: 8), Icon(Icons.arrow_forward, size: 18)]))),
      const SizedBox(height: 32),
    ]));
  }

  Widget _lbl(String t, bool r) => Padding(padding: const EdgeInsets.only(top: 12, bottom: 6), child: RichText(text: TextSpan(style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppTheme.teal), children: [TextSpan(text: t), if (r) const TextSpan(text: ' *', style: TextStyle(color: Colors.red))])));
  Widget _slbl(String t, bool r) => Padding(padding: const EdgeInsets.only(bottom: 4), child: RichText(text: TextSpan(style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.charcoal), children: [TextSpan(text: t), if (r) const TextSpan(text: ' *', style: TextStyle(color: Colors.red))])));
  Widget _inp(TextEditingController c, String h, {TextInputType? keyboard, int maxLines = 1, bool readOnly = false, String? Function(String?)? validator}) =>
    Padding(padding: const EdgeInsets.only(bottom: 4), child: TextFormField(controller: c, keyboardType: keyboard, maxLines: maxLines, readOnly: readOnly, validator: validator,
      style: readOnly ? TextStyle(color: Colors.grey[600]) : null,
      decoration: InputDecoration(hintText: h, hintStyle: TextStyle(color: AppTheme.textLight, fontSize: 14), filled: readOnly, fillColor: readOnly ? Colors.grey[100] : null)));
  Widget _dd(String v, List<String> items, String h, void Function(String?) oc) => Padding(padding: const EdgeInsets.only(bottom: 4), child: DropdownButtonFormField<String>(value: items.contains(v) ? v : '', hint: Text(h), items: items.map((s) => DropdownMenuItem(value: s, child: Text(s.isEmpty ? '— Select —' : s))).toList(), onChanged: oc));
}

// ─── Optional Tours Form (with seat limits) ─────────────────
class _ToursForm extends StatefulWidget {
  final Map<String, dynamic>? data;
  final Map<String, dynamic> avail;
  final VoidCallback onBack;
  final Future<void> Function(Map<String, dynamic>) onSubmit;
  const _ToursForm({this.data, required this.avail, required this.onBack, required this.onSubmit});
  @override
  State<_ToursForm> createState() => _ToursFormState();
}

class _ToursFormState extends State<_ToursForm> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  final _api = ApiClient();
  bool _loading = false;
  String _sept12 = '', _sept13Yoga = '', _sept14 = '';

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    if (d != null) {
      _sept12 = d['sept12_choice'] ?? ''; _sept13Yoga = d['sept13_yoga'] ?? ''; _sept14 = d['sept14_choice'] ?? '';
      if (_sept12 == 'heritage_walk') _sept12 = 'art_walk';
    }
  }

  int _remaining(String day, String id) { final t = widget.avail[day]?[id]; return t?['remaining'] ?? 999; }
  int _limit(String day, String id) { final t = widget.avail[day]?[id]; return t?['limit'] ?? 0; }
  bool _isAvail(String day, String id) {
    if (day == 'sept12' && _sept12 == id) return true;
    if (day == 'sept14' && _sept14 == id) return true;
    return _remaining(day, id) > 0;
  }

  Future<void> _submit() async {
    if (_sept12.isEmpty) { _snack('Please select a 12 Sept tour option'); return; }
    if (_sept13Yoga.isEmpty) { _snack('Please select a 13 Sept Yoga option'); return; }
    if (_sept14.isEmpty) { _snack('Please select a 14 Sept tour option'); return; }
    setState(() => _loading = true);
    final fields = {'sept12_choice': _sept12, 'sept13_yoga': _sept13Yoga, 'sept14_choice': _sept14, 'source': 'app'};
    final result = await _api.submitOptionalTours(fields);
    setState(() => _loading = false);
    if (!mounted) return;
    if (result['success'] == true) { await widget.onSubmit(fields); }
    else { _snack(result['message'] ?? 'Error'); }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700));

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(padding: const EdgeInsets.all(16), children: [
      const Text('Optional Tours Registration Form', style: TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text('Select the optional tours you\'d like to join.', style: TextStyle(fontSize: 13, color: AppTheme.textMid)),
      const SizedBox(height: 12),
      Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.gold.withOpacity(0.06), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.gold.withOpacity(0.2))),
        child: Text('Please share your interest by 01 August 2026 so we can make the necessary arrangements.', style: TextStyle(fontSize: 13, color: AppTheme.gold, fontWeight: FontWeight.w600))),
      const SizedBox(height: 20),

      _section('Q1: 12 Sept 2026', 'Afternoon (1400–1600)', [
        _tourRadio('sept12', 'orientation', 'Jaipur Orientation Tour by Pink Rickshaw', '🛺'),
        _tourRadio('sept12', 'art_walk', 'Art & Antiquities Walk', '🎨'),
        _tourRadio('sept12', 'block_printing', 'Hands-on Block Printing Workshop', '🖌️'),
        _tourRadio('sept12', 'none', 'None — free time', '😌', noLimit: true),
      ], isDark),
      const SizedBox(height: 16),

      _section('Q2: 13 Sept 2026', 'Morning (0630–0715)', [
        _simpleRadio('sept13', 'yes', 'Yes, I\'ll join the Yoga session', '🧘'),
        _simpleRadio('sept13', 'no', 'No, I\'ll skip this one', '😴'),
      ], isDark),
      const SizedBox(height: 16),

      _section('Q3: 14 Sept 2026', 'Morning', [
        _tourRadio('sept14', 'safari', 'Jhalana Safari (0500–0830)', '🐆'),
        _tourRadio('sept14', 'cycling', 'Jaipur Cycling Tour (0630–0830)', '🚴'),
        _tourRadio('sept14', 'temples', 'Temples & Havelis Walk (0730–0930)', '🛕'),
        _tourRadio('sept14', 'flowers', 'Great Exotic Flower Tour (0715–1000)', '🌺'),
        _tourRadio('sept14', 'rickshaw', 'Pink Rickshaw + Observatory (0800–1000)', '🛺'),
        _tourRadio('sept14', 'none', 'None — sleep in', '😌', noLimit: true),
      ], isDark),

      const SizedBox(height: 28),
      Row(children: [
        Expanded(child: SizedBox(height: 50, child: OutlinedButton.icon(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back, size: 18), label: const Text('BACK')))),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: SizedBox(height: 50, child: ElevatedButton(onPressed: _loading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold),
          child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('SAVE & SUBMIT', style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1)), SizedBox(width: 8), Icon(Icons.check, size: 18)])))),
      ]),
      const SizedBox(height: 32),
    ]);
  }

  Widget _section(String title, String sub, List<Widget> children, bool isDark) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(title, style: const TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.w700)),
    Text(sub, style: TextStyle(fontSize: 12, color: AppTheme.textMid)), const SizedBox(height: 12), ...children])));

  Widget _tourRadio(String day, String value, String label, String emoji, {bool noLimit = false}) {
    final avail = noLimit || _isAvail(day, value);
    final rem = noLimit ? -1 : _remaining(day, value);
    final lim = noLimit ? 0 : _limit(day, value);
    final full = !noLimit && !avail;
    final seatText = noLimit ? '' : full ? 'FULLY BOOKED' : '$rem / $lim seats left';
    final seatColor = full ? Colors.red : (rem <= 5 ? Colors.orange : AppTheme.teal);

    String cv; void Function(String?) oc;
    switch (day) { case 'sept12': cv = _sept12; oc = (v) => setState(() => _sept12 = v ?? ''); break;
      case 'sept14': cv = _sept14; oc = (v) => setState(() => _sept14 = v ?? ''); break;
      default: cv = ''; oc = (_) {}; }

    return Opacity(opacity: full ? 0.4 : 1, child: RadioListTile<String>(value: value, groupValue: cv, onChanged: full ? null : oc,
      title: Text('$emoji  $label', style: TextStyle(fontSize: 14, color: full ? Colors.grey : null)),
      subtitle: seatText.isNotEmpty ? Padding(padding: const EdgeInsets.only(left: 28), child: Text(seatText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: seatColor))) : null,
      dense: true, contentPadding: EdgeInsets.zero, activeColor: AppTheme.teal));
  }

  Widget _simpleRadio(String g, String v, String l, String e) {
    String cv; void Function(String?) oc;
    if (g == 'sept13') { cv = _sept13Yoga; oc = (x) => setState(() => _sept13Yoga = x ?? ''); } else { cv = ''; oc = (_) {}; }
    return RadioListTile<String>(value: v, groupValue: cv, onChanged: oc, title: Text('$e  $l', style: const TextStyle(fontSize: 14)), dense: true, contentPadding: EdgeInsets.zero, activeColor: AppTheme.teal);
  }
}
