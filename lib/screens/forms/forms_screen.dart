import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../data/api_client.dart';
import '../../providers/providers.dart';

/// Registration form — 100% dynamic from website API.
/// Participant form fields, tour options, labels, seat limits — all from server.

class FormsScreen extends ConsumerStatefulWidget {
  const FormsScreen({super.key});
  @override
  ConsumerState<FormsScreen> createState() => _FormsScreenState();
}

enum RegistrationState { loading, neitherSubmitted, pinfoOnly, toursOnly, bothSubmitted }

class _FormsScreenState extends ConsumerState<FormsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _api = ApiClient();
  RegistrationState _formState = RegistrationState.loading;
  Map<String, dynamic>? _pinfoData;
  Map<String, dynamic>? _toursData;
  Map<String, dynamic>? _formConfig;

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 3, vsync: this); _loadAll(); }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _loadAll() async {
    setState(() => _formState = RegistrationState.loading);
    try {
      final results = await Future.wait([_api.getParticipantInfo(), _api.getOptionalTours(), _api.getFormConfig()]);
      bool pFilled = false, tFilled = false;

      if (results[0]['success'] == true && results[0]['data'] != null && (results[0]['data']['full_name'] ?? '').toString().isNotEmpty) {
        _pinfoData = results[0]['data']; pFilled = true;
      }
      if (results[1]['success'] == true && results[1]['data'] != null) {
        final d = results[1]['data'];
        if ((d['sept12_choice'] ?? '').toString().isNotEmpty || (d['sept13_yoga'] ?? '').toString().isNotEmpty || (d['sept14_choice'] ?? '').toString().isNotEmpty) {
          _toursData = d; tFilled = true;
        }
      }
      if (results[2]['success'] == true && results[2]['data'] != null) {
        _formConfig = results[2]['data'];
      }

      if (pFilled && tFilled) { _formState = RegistrationState.bothSubmitted; _tabCtrl.animateTo(2); }
      else if (pFilled && !tFilled) { _formState = RegistrationState.pinfoOnly; _tabCtrl.animateTo(1); }
      else if (!pFilled && tFilled) { _formState = RegistrationState.toursOnly; _tabCtrl.animateTo(0); }
      else { _formState = RegistrationState.neitherSubmitted; _tabCtrl.animateTo(0); }
    } catch (_) { _formState = RegistrationState.neitherSubmitted; }
    setState(() {});
  }

  // Tab labels from API
  String _tabLabel(String key, String fallback) => (_formConfig?['tabs']?[key] ?? fallback).toString();

  @override
  Widget build(BuildContext context) {
    final locked0 = _formState == RegistrationState.bothSubmitted;
    final locked1 = _formState == RegistrationState.bothSubmitted || _formState == RegistrationState.toursOnly;
    return Scaffold(
      appBar: AppBar(title: const Text('Registration'),
        bottom: TabBar(controller: _tabCtrl, indicatorColor: AppTheme.goldLight, labelColor: Colors.white, unselectedLabelColor: Colors.white60,
          onTap: (i) { if ((i == 0 && locked0) || (i == 1 && locked1) || (i == 2 && _formState != RegistrationState.bothSubmitted)) _tabCtrl.animateTo(_tabCtrl.previousIndex); },
          tabs: [
            Tab(child: Opacity(opacity: locked0 ? 0.4 : 1, child: Text(_tabLabel('tab_pinfo', 'Participant Info')))),
            Tab(child: Opacity(opacity: locked1 ? 0.4 : 1, child: Text(_tabLabel('tab_tours', 'Optional Tours')))),
            Tab(child: Opacity(opacity: _formState == RegistrationState.bothSubmitted ? 1 : 0.4, child: Text(_tabLabel('tab_confirm', 'Confirmation')))),
          ])),
      body: _formState == RegistrationState.loading
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(controller: _tabCtrl, physics: const NeverScrollableScrollPhysics(), children: [
            locked0 ? _lockedPanel(_formConfig?['confirmation']?['pinfo_locked_title'] ?? 'Submitted', _formConfig?['confirmation']?['pinfo_locked_message'] ?? '') : _ParticipantForm(data: _pinfoData, config: _formConfig?['participant_form'], onContinue: _onPinfoContinue),
            locked1 ? _lockedToursPanel() : _ToursForm(data: _toursData, config: _formConfig, onBack: () => _tabCtrl.animateTo(0), onSubmit: _onToursSubmit),
            _confirmationPanel(),
          ]),
    );
  }

  Widget _lockedPanel(String title, String message) => Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 52, height: 52, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.teal.withOpacity(0.1)), child: const Icon(Icons.check, color: AppTheme.teal, size: 28)),
    const SizedBox(height: 16), Text(title, style: const TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w700)),
    if (message.isNotEmpty) ...[const SizedBox(height: 8), Text(message, style: TextStyle(fontSize: 14, color: AppTheme.textMid), textAlign: TextAlign.center)]])));

  Widget _lockedToursPanel() {
    if (_formState == RegistrationState.toursOnly) {
      final msg = _formConfig?['confirmation']?['tours_only_message'] ?? '';
      return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.amber.withOpacity(0.15)), child: const Icon(Icons.check, color: Colors.amber, size: 24)),
        const SizedBox(height: 16), Text(_formConfig?['confirmation']?['tours_locked_title'] ?? 'Tours submitted', style: const TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.amber), textAlign: TextAlign.center),
        if (msg.isNotEmpty) ...[const SizedBox(height: 8), Text(msg, style: TextStyle(fontSize: 14, color: AppTheme.textMid), textAlign: TextAlign.center)]])));
    }
    return _lockedPanel(_formConfig?['confirmation']?['tours_locked_title'] ?? 'Submitted', _formConfig?['confirmation']?['tours_locked_message'] ?? '');
  }

  Widget _confirmationPanel() {
    if (_formState != RegistrationState.bothSubmitted) return Center(child: Text(_formConfig?['confirmation']?['incomplete_message'] ?? '', style: TextStyle(color: AppTheme.textMid)));
    final title = _formConfig?['confirmation']?['title'] ?? '';
    final msg = _formConfig?['confirmation']?['message'] ?? '';
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 52, height: 52, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.gold.withOpacity(0.1)), child: Icon(Icons.check, color: AppTheme.gold, size: 28)),
      const SizedBox(height: 16), Text(title, style: const TextStyle(fontFamily: 'serif', fontSize: 20, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10), Text(msg, style: TextStyle(fontSize: 14, color: AppTheme.textMid, height: 1.6), textAlign: TextAlign.center)])));
  }

  void _onPinfoContinue() { setState(() { _formState = RegistrationState.pinfoOnly; }); _tabCtrl.animateTo(1); }
  Future<void> _onToursSubmit(Map<String, dynamic> f) async { setState(() { _formState = RegistrationState.bothSubmitted; }); _tabCtrl.animateTo(2); }
}

// ─── DYNAMIC Participant Info Form ──────────────────────────
class _ParticipantForm extends StatefulWidget {
  final Map<String, dynamic>? data;
  final Map<String, dynamic>? config;
  final VoidCallback onContinue;
  const _ParticipantForm({this.data, this.config, required this.onContinue});
  @override
  State<_ParticipantForm> createState() => _ParticipantFormState();
}

class _ParticipantFormState extends State<_ParticipantForm> with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true;
  final _api = ApiClient(); final _formKey = GlobalKey<FormState>();
  bool _loading = false, _certify = false;

  // Dynamic controllers and values keyed by field key
  final Map<String, TextEditingController> _textCtrl = {};
  final Map<String, String> _dropdownVal = {};
  String _chipVal = ''; // for meal_preference
  String _gender = '';

  @override
  void initState() { super.initState(); _init(); }

  void _init() {
    final fields = (widget.config?['fields'] as List?) ?? [];
    final d = widget.data;
    for (final f in fields) {
      final key = f['key']?.toString() ?? '';
      final type = f['type']?.toString() ?? '';
      if (key.startsWith('_')) continue; // headers
      if (type == 'dropdown') {
        _dropdownVal[key] = d?[key]?.toString() ?? '';
        if (key == 'gender') _gender = _dropdownVal[key] ?? '';
        // Also init "other" text controller if has_other
        if (f['has_other'] == true) {
          final otherKey = f['other_key']?.toString() ?? '${key}_other';
          _textCtrl[otherKey] = TextEditingController(text: d?[otherKey]?.toString() ?? '');
        }
      } else if (type == 'chips') {
        _chipVal = d?[key]?.toString() ?? '';
      } else if (type != 'header') {
        _textCtrl[key] = TextEditingController(text: d?[key]?.toString() ?? '');
      }
    }
  }

  @override
  void dispose() { _textCtrl.values.forEach((c) => c.dispose()); super.dispose(); }

  bool _shouldShow(Map<String, dynamic> field) {
    final sw = field['show_when'];
    if (sw == null) return true;
    final f = sw['field']?.toString() ?? '';
    final v = sw['value']?.toString() ?? '';
    if (f == 'gender') return _gender == v;
    return (_dropdownVal[f] ?? '') == v;
  }

  String _resolveLabel(Map<String, dynamic> field) {
    final base = field['label']?.toString() ?? '';
    final prefixM = field['label_prefix_male']?.toString();
    final prefixF = field['label_prefix_female']?.toString();
    if (prefixM != null && _gender == 'Male') return '$prefixM: $base';
    if (prefixF != null && _gender == 'Female') return '$prefixF: $base';
    if (prefixM != null) return '$prefixM: $base'; // default to male numbering
    return base;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_certify) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.config?['certification_text'] ?? 'Please tick the certification'), backgroundColor: Colors.red)); return; }
    FocusScope.of(context).unfocus(); setState(() => _loading = true);

    final body = <String, dynamic>{};
    final fields = (widget.config?['fields'] as List?) ?? [];
    for (final f in fields) {
      final key = f['key']?.toString() ?? '';
      if (key.startsWith('_')) continue;
      final type = f['type']?.toString() ?? '';
      if (type == 'dropdown') {
        body[key] = _dropdownVal[key] ?? '';
        if (f['has_other'] == true) {
          final otherKey = f['other_key']?.toString() ?? '${key}_other';
          body[otherKey] = _textCtrl[otherKey]?.text.trim() ?? '';
        }
      } else if (type == 'chips') {
        body[key] = _chipVal;
      } else if (type != 'header') {
        body[key] = _textCtrl[key]?.text.trim() ?? '';
      }
    }
    body['source'] = 'app';

    final result = await _api.submitParticipantInfo(body);
    setState(() => _loading = false); if (!mounted) return;
    if (result['success'] == true) { widget.onContinue(); }
    else { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Error'), backgroundColor: Colors.red.shade700)); }
  }

  @override
  Widget build(BuildContext context) { super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fields = (widget.config?['fields'] as List?) ?? [];
    final title = widget.config?['title']?.toString() ?? '';
    final saveBtn = widget.config?['save_button']?.toString() ?? 'SAVE & CONTINUE';
    final certText = widget.config?['certification_text']?.toString() ?? '';

    return Form(key: _formKey, child: ListView(padding: const EdgeInsets.all(16), children: [
      if (title.isNotEmpty) Text(title, style: const TextStyle(fontFamily: 'serif', fontSize: 20, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),

      // Render fields dynamically
      for (final f in fields)
        if (_shouldShow(Map<String, dynamic>.from(f)))
          _buildField(Map<String, dynamic>.from(f), isDark),

      const SizedBox(height: 8),
      // Certification checkbox
      if (certText.isNotEmpty)
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Checkbox(value: _certify, activeColor: AppTheme.teal, onChanged: (v) => setState(() => _certify = v ?? false)),
          Expanded(child: GestureDetector(onTap: () => setState(() => _certify = !_certify),
            child: Padding(padding: const EdgeInsets.only(top: 12), child: Text(certText,
              style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : AppTheme.textMid, height: 1.5))))),
        ]),
      const SizedBox(height: 20),
      SizedBox(height: 50, child: ElevatedButton(onPressed: _loading ? null : _save, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold),
        child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(saveBtn, style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1)), const SizedBox(width: 8), const Icon(Icons.arrow_forward, size: 18)]))),
      const SizedBox(height: 32),
    ]));
  }

  Widget _buildField(Map<String, dynamic> field, bool isDark) {
    final key = field['key']?.toString() ?? '';
    final type = field['type']?.toString() ?? '';
    final label = _resolveLabel(field);
    final required = field['required'] == true;
    final placeholder = field['placeholder']?.toString() ?? '';
    final readOnlyPre = field['readonly_prefilled'] == true && widget.data != null && (_textCtrl[key]?.text.isNotEmpty == true);
    final maxLines = (field['max_lines'] as int?) ?? 1;

    if (type == 'header') {
      return _lbl(label, required);
    }

    final widgets = <Widget>[];
    widgets.add(_lbl(label, required));

    switch (type) {
      case 'text': case 'date': case 'email': case 'phone': case 'textarea':
        TextInputType? kb;
        if (type == 'email') kb = TextInputType.emailAddress;
        if (type == 'phone') kb = TextInputType.phone;
        if (type == 'date') kb = TextInputType.datetime;
        final lines = type == 'textarea' ? (maxLines > 1 ? maxLines : 3) : maxLines;
        widgets.add(_inp(_textCtrl[key] ?? TextEditingController(), placeholder, keyboard: kb, maxLines: lines, readOnly: readOnlyPre,
          validator: required ? (v) => (v == null || v.isEmpty) ? 'Required' : null : null));
        break;

      case 'dropdown':
        final options = (field['options'] as List?)?.map((e) => e.toString()).toList() ?? [];
        final allOpts = ['', ...options];
        final val = _dropdownVal[key] ?? '';
        widgets.add(_dd(allOpts.contains(val) ? val : '', allOpts, 'Select', (v) {
          setState(() {
            _dropdownVal[key] = v ?? '';
            if (key == 'gender') _gender = v ?? '';
          });
        }));
        // "Other" text field
        if (field['has_other'] == true && (_dropdownVal[key] ?? '').contains('Other')) {
          final otherKey = field['other_key']?.toString() ?? '${key}_other';
          widgets.add(_inp(_textCtrl[otherKey] ?? TextEditingController(), field['other_placeholder']?.toString() ?? 'Specify'));
        }
        break;

      case 'chips':
        final options = (field['options'] as List?)?.map((e) => e.toString()).toList() ?? [];
        widgets.add(Padding(padding: const EdgeInsets.only(bottom: 16), child: Wrap(spacing: 8, runSpacing: 8, children: [
          for (final m in options)
            ChoiceChip(label: Text(m, style: TextStyle(fontSize: 13, color: _chipVal == m ? Colors.white : (isDark ? Colors.grey[300] : AppTheme.charcoal))),
              selected: _chipVal == m, selectedColor: AppTheme.teal, backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: _chipVal == m ? AppTheme.teal : AppTheme.border)),
              onSelected: (_) => setState(() => _chipVal = m)),
        ])));
        break;
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }

  Widget _lbl(String t, bool r) => Padding(padding: const EdgeInsets.only(top: 12, bottom: 6), child: RichText(text: TextSpan(style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppTheme.teal), children: [TextSpan(text: t.toUpperCase()), if (r) const TextSpan(text: ' *', style: TextStyle(color: Colors.red))])));
  Widget _inp(TextEditingController c, String h, {TextInputType? keyboard, int maxLines = 1, bool readOnly = false, String? Function(String?)? validator}) =>
    Padding(padding: const EdgeInsets.only(bottom: 4), child: TextFormField(controller: c, keyboardType: keyboard, maxLines: maxLines, readOnly: readOnly, validator: validator,
      style: readOnly ? TextStyle(color: Colors.grey[600]) : null,
      decoration: InputDecoration(hintText: h, hintStyle: TextStyle(color: AppTheme.textLight, fontSize: 14), filled: readOnly, fillColor: readOnly ? Colors.grey[100] : null)));
  Widget _dd(String v, List<String> items, String h, void Function(String?) oc) => Padding(padding: const EdgeInsets.only(bottom: 4), child: DropdownButtonFormField<String>(value: items.contains(v) ? v : '', hint: Text(h), items: items.map((s) => DropdownMenuItem(value: s, child: Text(s.isEmpty ? '— Select —' : s))).toList(), onChanged: oc));
}

// ─── Optional Tours — FULLY DYNAMIC from get_form_config API ─
class _ToursForm extends StatefulWidget {
  final Map<String, dynamic>? data;
  final Map<String, dynamic>? config;
  final VoidCallback onBack;
  final Future<void> Function(Map<String, dynamic>) onSubmit;
  const _ToursForm({this.data, this.config, required this.onBack, required this.onSubmit});
  @override
  State<_ToursForm> createState() => _ToursFormState();
}

class _ToursFormState extends State<_ToursForm> with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true;
  final _api = ApiClient();
  bool _loading = false;
  final Map<String, String> _selections = {};

  @override
  void initState() { super.initState(); _prefill(); }

  void _prefill() {
    final d = widget.data;
    if (d == null) return;
    for (final section in (widget.config?['sections'] as List? ?? [])) {
      final field = section['field']?.toString() ?? '';
      final val = d[field]?.toString() ?? '';
      if (val.isNotEmpty) {
        _selections[field] = val == 'heritage_walk' ? 'art_walk' : val;
      }
    }
  }

  Map<String, dynamic> get _avail => Map<String, dynamic>.from(widget.config?['availability'] ?? {});

  int _remaining(String sectionKey, String optionId) {
    final a = _avail[sectionKey]?[optionId]; return a?['remaining'] ?? 999;
  }
  int _limit(String sectionKey, String optionId) {
    final a = _avail[sectionKey]?[optionId]; return a?['limit'] ?? 0;
  }
  bool _isAvail(String sectionKey, String field, String optionId) {
    if (_selections[field] == optionId) return true;
    return _remaining(sectionKey, optionId) > 0;
  }

  Future<void> _submit() async {
    for (final section in (widget.config?['sections'] as List? ?? [])) {
      final field = section['field']?.toString() ?? '';
      final title = section['title']?.toString() ?? '';
      if ((_selections[field] ?? '').isEmpty) {
        _snack('Please make a selection for $title');
        return;
      }
    }
    setState(() => _loading = true);
    final fields = Map<String, dynamic>.from(_selections);
    fields['source'] = 'app';
    final result = await _api.submitOptionalTours(fields);
    setState(() => _loading = false);
    if (!mounted) return;
    if (result['success'] == true) { await widget.onSubmit(fields); }
    else { _snack(result['message'] ?? 'Error'); }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700));

  @override
  Widget build(BuildContext context) { super.build(context);
    final sections = (widget.config?['sections'] as List? ?? []);
    final deadline = widget.config?['deadline']?.toString() ?? '';
    final toursForm = widget.config?['tours_form'] as Map?;
    final title = toursForm?['title']?.toString() ?? '';
    final desc = toursForm?['description']?.toString() ?? '';
    final submitBtn = toursForm?['submit_button']?.toString() ?? 'SAVE & SUBMIT';
    final backBtn = toursForm?['back_button']?.toString() ?? 'BACK';

    if (sections.isEmpty) return const Center(child: CircularProgressIndicator());

    return ListView(padding: const EdgeInsets.all(16), children: [
      if (title.isNotEmpty) Text(title, style: const TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w700)),
      if (desc.isNotEmpty) ...[const SizedBox(height: 4), Text(desc, style: TextStyle(fontSize: 13, color: AppTheme.textMid))],
      if (deadline.isNotEmpty) ...[ const SizedBox(height: 12),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.gold.withOpacity(0.06), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.gold.withOpacity(0.2))),
          child: Text('Please share your interest by $deadline so we can make the necessary arrangements.', style: TextStyle(fontSize: 13, color: AppTheme.gold, fontWeight: FontWeight.w600)))],
      const SizedBox(height: 20),

      for (int i = 0; i < sections.length; i++) ...[
        if (i > 0) const SizedBox(height: 16),
        _buildSection(sections[i]),
      ],

      const SizedBox(height: 28),
      Row(children: [
        Expanded(child: SizedBox(height: 50, child: OutlinedButton.icon(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back, size: 18), label: Text(backBtn)))),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: SizedBox(height: 50, child: ElevatedButton(onPressed: _loading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold),
          child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(submitBtn, style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1)), const SizedBox(width: 8), const Icon(Icons.check, size: 18)])))),
      ]),
      const SizedBox(height: 32),
    ]);
  }

  Widget _buildSection(dynamic section) {
    final key = section['key']?.toString() ?? '';
    final field = section['field']?.toString() ?? '';
    final title = section['title']?.toString() ?? '';
    final subtitle = section['subtitle']?.toString() ?? '';
    final options = (section['options'] as List? ?? []);

    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.w700)),
      if (subtitle.isNotEmpty) Text(subtitle, style: TextStyle(fontSize: 12, color: AppTheme.textMid)),
      const SizedBox(height: 12),
      for (final opt in options) _buildOption(key, field, opt),
    ])));
  }

  Widget _buildOption(String sectionKey, String field, dynamic opt) {
    final id = opt['id']?.toString() ?? '';
    final name = opt['name']?.toString() ?? '';
    final maxSeats = opt['max_seats'] ?? 0;
    final isNone = id == 'none' || id == 'yes' || id == 'no';
    final hasLimit = maxSeats > 0 && !isNone;

    final avail = !hasLimit || _isAvail(sectionKey, field, id);
    final rem = hasLimit ? _remaining(sectionKey, id) : -1;
    final lim = hasLimit ? _limit(sectionKey, id) : 0;
    final full = hasLimit && !avail;

    final seatText = (!hasLimit || lim <= 0) ? '' : full ? 'FULLY BOOKED' : '$rem / $lim seats left';
    final seatColor = full ? Colors.red : (rem > 0 && rem <= 5 ? Colors.orange : AppTheme.teal);

    final cv = _selections[field] ?? '';

    return Opacity(opacity: full ? 0.4 : 1, child: RadioListTile<String>(
      value: id, groupValue: cv,
      onChanged: full ? null : (v) => setState(() => _selections[field] = v ?? ''),
      title: Text(name, style: TextStyle(fontSize: 14, color: full ? Colors.grey : null)),
      subtitle: seatText.isNotEmpty ? Padding(padding: const EdgeInsets.only(left: 28),
        child: Text(seatText, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: seatColor))) : null,
      dense: true, contentPadding: EdgeInsets.zero, activeColor: AppTheme.teal));
  }
}
