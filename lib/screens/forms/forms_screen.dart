import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../data/api_client.dart';
import '../../providers/providers.dart';

/// Registration — 3-step flow: Participant Info → Optional Tours → Confirmation
/// Tours tab locked until Participant Info saved. Confirmation locked until both saved.

class FormsScreen extends ConsumerStatefulWidget {
  const FormsScreen({super.key});
  @override
  ConsumerState<FormsScreen> createState() => _FormsScreenState();
}

enum RegState { loading, neitherDone, pinfoOnly, toursOnly, bothDone }

class _FormsScreenState extends ConsumerState<FormsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _api = ApiClient();
  RegState _state = RegState.loading;
  Map<String, dynamic>? _pinfoData, _toursData, _formConfig;

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 3, vsync: this); _loadAll(); }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  Future<void> _loadAll() async {
    setState(() => _state = RegState.loading);
    try {
      final res = await Future.wait([_api.getParticipantInfo(), _api.getOptionalTours(), _api.getFormConfig()]);
      bool pDone = false, tDone = false;
      if (res[0]['success'] == true && res[0]['data'] != null && (res[0]['data']['full_name'] ?? '').toString().isNotEmpty) {
        _pinfoData = res[0]['data']; pDone = true;
      }
      if (res[1]['success'] == true && res[1]['data'] != null) {
        final d = res[1]['data'];
        if ((d['sept12_choice'] ?? '').toString().isNotEmpty || (d['sept13_yoga'] ?? '').toString().isNotEmpty || (d['sept14_choice'] ?? '').toString().isNotEmpty) {
          _toursData = d; tDone = true;
        }
      }
      if (res[2]['success'] == true && res[2]['data'] != null) _formConfig = res[2]['data'];
      if (pDone && tDone) { _state = RegState.bothDone; _tabCtrl.animateTo(2); }
      else if (pDone) { _state = RegState.pinfoOnly; _tabCtrl.animateTo(1); }
      else if (tDone) { _state = RegState.toursOnly; }
      else { _state = RegState.neitherDone; }
    } catch (_) { _state = RegState.neitherDone; }
    setState(() {});
  }

  String _tab(String k, String fb) => (_formConfig?['tabs']?[k] ?? fb).toString();
  bool get _pinfoLocked => _state == RegState.bothDone;
  bool get _toursLocked => _state == RegState.bothDone || _state == RegState.neitherDone;
  bool get _confirmLocked => _state != RegState.bothDone;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registration'),
        bottom: TabBar(controller: _tabCtrl, indicatorColor: AppTheme.goldLight, labelColor: Colors.white, unselectedLabelColor: Colors.white60,
          onTap: (i) {
            if (i == 0 && _pinfoLocked) { _tabCtrl.animateTo(_tabCtrl.previousIndex); return; }
            if (i == 1 && _toursLocked) {
              _tabCtrl.animateTo(_tabCtrl.previousIndex);
              if (_state == RegState.neitherDone) _showMsg('Please complete Participant Info first');
              return;
            }
            if (i == 2 && _confirmLocked) {
              _tabCtrl.animateTo(_tabCtrl.previousIndex);
              _showMsg('Please complete all forms first');
              return;
            }
          },
          tabs: [
            Tab(child: _tabItem(_tab('tab_pinfo', 'Participant Info'), !_pinfoLocked, _state != RegState.neitherDone && _state != RegState.loading)),
            Tab(child: _tabItem(_tab('tab_tours', 'Optional Tours'), !_toursLocked, _state == RegState.bothDone || _state == RegState.toursOnly)),
            Tab(child: _tabItem(_tab('tab_confirm', 'Confirmation'), !_confirmLocked, _state == RegState.bothDone)),
          ])),
      body: _state == RegState.loading
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(controller: _tabCtrl, physics: const NeverScrollableScrollPhysics(), children: [
            _pinfoLocked ? _lockedPanel(Icons.check_circle, AppTheme.teal, _formConfig?['confirmation']?['pinfo_locked_title'] ?? 'Submitted', _formConfig?['confirmation']?['pinfo_locked_message'] ?? 'Your details have been received.')
              : _PinfoForm(data: _pinfoData, config: _formConfig?['participant_form'], onSaved: _onPinfoSaved),
            _toursLocked
              ? (_state == RegState.neitherDone
                  ? _lockedPanel(Icons.lock_outline, AppTheme.textLight, 'Complete Step 1', 'Fill in your Participant Info to unlock Optional Tours.')
                  : _lockedPanel(Icons.check_circle, AppTheme.teal, _formConfig?['confirmation']?['tours_locked_title'] ?? 'Submitted', _formConfig?['confirmation']?['tours_locked_message'] ?? ''))
              : _ToursForm(data: _toursData, config: _formConfig, onBack: () => _tabCtrl.animateTo(0), onSubmit: _onToursSubmit),
            _confirmPanel(),
          ]),
    );
  }

  Widget _tabItem(String label, bool active, bool done) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      if (done) Padding(padding: const EdgeInsets.only(right: 4), child: Icon(Icons.check_circle, size: 14, color: active ? AppTheme.goldLight : Colors.white38)),
      Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: active ? null : Colors.white38))),
    ]);
  }

  void _showMsg(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));

  Widget _lockedPanel(IconData icon, Color color, String title, String msg) => Center(child: Padding(padding: const EdgeInsets.all(40),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 56, height: 56, decoration: BoxDecoration(shape: BoxShape.circle, color: color.withOpacity(0.1)),
        child: Icon(icon, color: color, size: 28)),
      const SizedBox(height: 16),
      Text(title, style: const TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
      if (msg.isNotEmpty) ...[const SizedBox(height: 8), Text(msg, style: TextStyle(fontSize: 14, color: AppTheme.textMid, height: 1.5), textAlign: TextAlign.center)],
    ])));

  Widget _confirmPanel() {
    if (_state != RegState.bothDone) return _lockedPanel(Icons.hourglass_empty, AppTheme.textLight, 'Almost There', _formConfig?['confirmation']?['incomplete_message'] ?? 'Complete both forms to see your confirmation.');
    final title = _formConfig?['confirmation']?['title'] ?? 'Registration Complete';
    final msg = _formConfig?['confirmation']?['message'] ?? 'Thank you! Your details have been submitted successfully.';
    return Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 64, height: 64, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.gold.withOpacity(0.1)),
        child: Icon(Icons.celebration, color: AppTheme.gold, size: 32)),
      const SizedBox(height: 20),
      Text(title, style: const TextStyle(fontFamily: 'serif', fontSize: 22, fontWeight: FontWeight.w700), textAlign: TextAlign.center),
      const SizedBox(height: 12),
      Text(msg, style: TextStyle(fontSize: 14, color: AppTheme.textMid, height: 1.6), textAlign: TextAlign.center),
    ])));
  }

  void _onPinfoSaved() { setState(() => _state = RegState.pinfoOnly); _tabCtrl.animateTo(1); }
  Future<void> _onToursSubmit(Map<String, dynamic> f) async { setState(() => _state = RegState.bothDone); _tabCtrl.animateTo(2); }
}

// ─── Participant Info Form ──────────────────────────
class _PinfoForm extends StatefulWidget {
  final Map<String, dynamic>? data, config;
  final VoidCallback onSaved;
  const _PinfoForm({this.data, this.config, required this.onSaved});
  @override
  State<_PinfoForm> createState() => _PinfoFormState();
}

class _PinfoFormState extends State<_PinfoForm> with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true;
  final _api = ApiClient(); final _formKey = GlobalKey<FormState>();
  bool _loading = false, _certify = false;
  final Map<String, TextEditingController> _ctrl = {};
  final Map<String, String> _ddVal = {};
  String _chipVal = '', _gender = '';

  @override
  void initState() { super.initState(); _init(); }

  void _init() {
    final fields = (widget.config?['fields'] as List?) ?? [];
    final d = widget.data;
    for (final f in fields) {
      final k = f['key']?.toString() ?? '';
      final t = f['type']?.toString() ?? '';
      if (k.startsWith('_')) continue;
      if (t == 'dropdown') {
        _ddVal[k] = d?[k]?.toString() ?? '';
        if (k == 'gender') _gender = _ddVal[k] ?? '';
        if (f['has_other'] == true) {
          final ok = f['other_key']?.toString() ?? '${k}_other';
          _ctrl[ok] = TextEditingController(text: d?[ok]?.toString() ?? '');
        }
      } else if (t == 'chips') { _chipVal = d?[k]?.toString() ?? ''; }
      else if (t != 'header') { _ctrl[k] = TextEditingController(text: d?[k]?.toString() ?? ''); }
    }
  }

  @override void dispose() { _ctrl.values.forEach((c) => c.dispose()); super.dispose(); }

  bool _show(Map<String, dynamic> f) {
    final sw = f['show_when']; if (sw == null) return true;
    final fld = sw['field']?.toString() ?? '', val = sw['value']?.toString() ?? '';
    return fld == 'gender' ? _gender == val : (_ddVal[fld] ?? '') == val;
  }

  String _lbl(Map<String, dynamic> f) {
    final base = f['label']?.toString() ?? '';
    final pm = f['label_prefix_male']?.toString(), pf = f['label_prefix_female']?.toString();
    if (pm != null && _gender == 'Male') return '$pm: $base';
    if (pf != null && _gender == 'Female') return '$pf: $base';
    if (pm != null) return '$pm: $base';
    return base;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_certify) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Please tick the certification'), backgroundColor: Colors.red)); return; }
    FocusScope.of(context).unfocus(); setState(() => _loading = true);
    final body = <String, dynamic>{};
    for (final f in (widget.config?['fields'] as List?) ?? []) {
      final k = f['key']?.toString() ?? '', t = f['type']?.toString() ?? '';
      if (k.startsWith('_')) continue;
      if (t == 'dropdown') { body[k] = _ddVal[k] ?? ''; if (f['has_other'] == true) { final ok = f['other_key']?.toString() ?? '${k}_other'; body[ok] = _ctrl[ok]?.text.trim() ?? ''; } }
      else if (t == 'chips') { body[k] = _chipVal; }
      else if (t != 'header') { body[k] = _ctrl[k]?.text.trim() ?? ''; }
    }
    body['source'] = 'app';
    final r = await _api.submitParticipantInfo(body);
    setState(() => _loading = false);
    if (!mounted) return;
    if (r['success'] == true) { widget.onSaved(); }
    else { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(r['message'] ?? 'Error'), backgroundColor: Colors.red.shade700)); }
  }

  @override
  Widget build(BuildContext context) { super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fields = (widget.config?['fields'] as List?) ?? [];
    final title = widget.config?['title']?.toString() ?? '';
    final saveBtn = widget.config?['save_button']?.toString() ?? 'SAVE & CONTINUE';
    final cert = widget.config?['certification_text']?.toString() ?? '';

    return Form(key: _formKey, child: ListView(padding: const EdgeInsets.all(16), children: [
      if (title.isNotEmpty) Text(title, style: const TextStyle(fontFamily: 'serif', fontSize: 20, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      for (final f in fields) if (_show(Map<String, dynamic>.from(f))) _field(Map<String, dynamic>.from(f), isDark),
      const SizedBox(height: 8),
      if (cert.isNotEmpty) Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Checkbox(value: _certify, activeColor: AppTheme.teal, onChanged: (v) => setState(() => _certify = v ?? false)),
        Expanded(child: GestureDetector(onTap: () => setState(() => _certify = !_certify),
          child: Padding(padding: const EdgeInsets.only(top: 12), child: Text(cert, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : AppTheme.textMid, height: 1.5))))),
      ]),
      const SizedBox(height: 20),
      SizedBox(height: 50, child: ElevatedButton(onPressed: _loading ? null : _save, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold),
        child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(saveBtn, style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1)), const SizedBox(width: 8), const Icon(Icons.arrow_forward, size: 18)]))),
      const SizedBox(height: 32),
    ]));
  }

  Widget _field(Map<String, dynamic> f, bool isDark) {
    final k = f['key']?.toString() ?? '', t = f['type']?.toString() ?? '';
    final label = _lbl(f); final req = f['required'] == true;
    final ph = f['placeholder']?.toString() ?? '';
    final roPre = f['readonly_prefilled'] == true && widget.data != null && (_ctrl[k]?.text.isNotEmpty == true);
    final ml = (f['max_lines'] as int?) ?? 1;

    if (t == 'header') return _labelW(label, req);
    final ws = <Widget>[]; ws.add(_labelW(label, req));
    switch (t) {
      case 'text': case 'date': case 'email': case 'phone': case 'textarea':
        TextInputType? kb;
        if (t == 'email') kb = TextInputType.emailAddress;
        if (t == 'phone') kb = TextInputType.phone;
        if (t == 'date') kb = TextInputType.datetime;
        ws.add(_inp(_ctrl[k] ?? TextEditingController(), ph, kb: kb, ml: t == 'textarea' ? (ml > 1 ? ml : 3) : ml, ro: roPre, v: req ? (v) => (v == null || v.isEmpty) ? 'Required' : null : null));
        break;
      case 'dropdown':
        final opts = (f['options'] as List?)?.map((e) => e.toString()).toList() ?? [];
        final all = ['', ...opts]; final val = _ddVal[k] ?? '';
        ws.add(_dd(all.contains(val) ? val : '', all, (v) { setState(() { _ddVal[k] = v ?? ''; if (k == 'gender') _gender = v ?? ''; }); }));
        if (f['has_other'] == true && (_ddVal[k] ?? '').contains('Other'))
          ws.add(_inp(_ctrl[f['other_key']?.toString() ?? '${k}_other'] ?? TextEditingController(), f['other_placeholder']?.toString() ?? 'Specify'));
        break;
      case 'chips':
        final opts = (f['options'] as List?)?.map((e) => e.toString()).toList() ?? [];
        ws.add(Padding(padding: const EdgeInsets.only(bottom: 16), child: Wrap(spacing: 8, runSpacing: 8, children: [
          for (final m in opts) ChoiceChip(label: Text(m, style: TextStyle(fontSize: 13, color: _chipVal == m ? Colors.white : (isDark ? Colors.grey[300] : AppTheme.charcoal))),
            selected: _chipVal == m, selectedColor: AppTheme.teal, backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: _chipVal == m ? AppTheme.teal : AppTheme.border)),
            onSelected: (_) => setState(() => _chipVal = m)),
        ])));
        break;
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: ws);
  }

  Widget _labelW(String t, bool r) => Padding(padding: const EdgeInsets.only(top: 12, bottom: 6),
    child: RichText(text: TextSpan(style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: AppTheme.teal),
      children: [TextSpan(text: t.toUpperCase()), if (r) const TextSpan(text: ' *', style: TextStyle(color: Colors.red))])));
  Widget _inp(TextEditingController c, String h, {TextInputType? kb, int ml = 1, bool ro = false, String? Function(String?)? v}) =>
    Padding(padding: const EdgeInsets.only(bottom: 4), child: TextFormField(controller: c, keyboardType: kb, maxLines: ml, readOnly: ro, validator: v,
      style: ro ? TextStyle(color: Colors.grey[600]) : null,
      decoration: InputDecoration(hintText: h, hintStyle: TextStyle(color: AppTheme.textLight, fontSize: 14), filled: ro, fillColor: ro ? Colors.grey[100] : null)));
  Widget _dd(String v, List<String> items, void Function(String?) oc) => Padding(padding: const EdgeInsets.only(bottom: 4),
    child: DropdownButtonFormField<String>(value: items.contains(v) ? v : '', hint: const Text('Select'), items: items.map((s) => DropdownMenuItem(value: s, child: Text(s.isEmpty ? '— Select —' : s))).toList(), onChanged: oc));
}

// ─── Optional Tours Form ──────────────────────────
class _ToursForm extends StatefulWidget {
  final Map<String, dynamic>? data, config;
  final VoidCallback onBack;
  final Future<void> Function(Map<String, dynamic>) onSubmit;
  const _ToursForm({this.data, this.config, required this.onBack, required this.onSubmit});
  @override State<_ToursForm> createState() => _ToursFormState();
}

class _ToursFormState extends State<_ToursForm> with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true;
  final _api = ApiClient(); bool _loading = false;
  final Map<String, String> _sel = {};

  @override void initState() { super.initState(); _prefill(); }
  void _prefill() { final d = widget.data; if (d == null) return;
    for (final s in (widget.config?['sections'] as List? ?? [])) {
      final f = s['field']?.toString() ?? '', v = d[f]?.toString() ?? '';
      if (v.isNotEmpty) _sel[f] = v == 'heritage_walk' ? 'art_walk' : v;
    }
  }

  Map<String, dynamic> get _avail => Map<String, dynamic>.from(widget.config?['availability'] ?? {});
  int _rem(String sk, String oid) { final a = _avail[sk]?[oid]; return a?['remaining'] ?? 999; }
  int _lim(String sk, String oid) { final a = _avail[sk]?[oid]; return a?['limit'] ?? 0; }
  bool _isAvail(String sk, String f, String oid) => _sel[f] == oid || _rem(sk, oid) > 0;

  Future<void> _submit() async {
    for (final s in (widget.config?['sections'] as List? ?? [])) {
      final f = s['field']?.toString() ?? '', t = s['title']?.toString() ?? '';
      if ((_sel[f] ?? '').isEmpty) { _snack('Please make a selection for $t'); return; }
    }
    setState(() => _loading = true);
    final body = Map<String, dynamic>.from(_sel)..['source'] = 'app';
    final r = await _api.submitOptionalTours(body);
    setState(() => _loading = false);
    if (!mounted) return;
    if (r['success'] == true) { await widget.onSubmit(body); }
    else { _snack(r['message'] ?? 'Error'); }
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.red.shade700));

  @override
  Widget build(BuildContext context) { super.build(context);
    final sections = widget.config?['sections'] as List? ?? [];
    final deadline = widget.config?['deadline']?.toString() ?? '';
    final tf = widget.config?['tours_form'] as Map?;
    final title = tf?['title']?.toString() ?? ''; final desc = tf?['description']?.toString() ?? '';
    final submitBtn = tf?['submit_button']?.toString() ?? 'SAVE & SUBMIT';
    final backBtn = tf?['back_button']?.toString() ?? 'BACK';
    if (sections.isEmpty) return const Center(child: CircularProgressIndicator());

    return ListView(padding: const EdgeInsets.all(16), children: [
      if (title.isNotEmpty) Text(title, style: const TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w700)),
      if (desc.isNotEmpty) ...[const SizedBox(height: 4), Text(desc, style: TextStyle(fontSize: 13, color: AppTheme.textMid))],
      if (deadline.isNotEmpty) ...[const SizedBox(height: 12),
        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.gold.withOpacity(0.06), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.gold.withOpacity(0.2))),
          child: Text('Please share your interest by $deadline so we can make the necessary arrangements.', style: TextStyle(fontSize: 13, color: AppTheme.gold, fontWeight: FontWeight.w600)))],
      const SizedBox(height: 20),
      for (int i = 0; i < sections.length; i++) ...[if (i > 0) const SizedBox(height: 16), _section(sections[i])],
      const SizedBox(height: 28),
      Row(children: [
        Expanded(child: SizedBox(height: 50, child: OutlinedButton.icon(onPressed: widget.onBack, icon: const Icon(Icons.arrow_back, size: 18), label: Text(backBtn)))),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: SizedBox(height: 50, child: ElevatedButton(onPressed: _loading ? null : _submit, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold),
          child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text(submitBtn, style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1)), const SizedBox(width: 8), const Icon(Icons.check, size: 18)])))),
      ]),
      const SizedBox(height: 32),
    ]);
  }

  Widget _section(dynamic s) {
    final k = s['key']?.toString() ?? '', f = s['field']?.toString() ?? '';
    final title = s['title']?.toString() ?? '', sub = s['subtitle']?.toString() ?? '';
    final opts = s['options'] as List? ?? [];
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.w700)),
      if (sub.isNotEmpty) Text(sub, style: TextStyle(fontSize: 12, color: AppTheme.textMid)),
      const SizedBox(height: 12),
      for (final o in opts) _opt(k, f, o),
    ])));
  }

  Widget _opt(String sk, String f, dynamic o) {
    final id = o['id']?.toString() ?? '', name = o['name']?.toString() ?? '';
    final ms = o['max_seats'] ?? 0; final isNone = id == 'none' || id == 'yes' || id == 'no';
    final hasLim = ms > 0 && !isNone;
    final avail = !hasLim || _isAvail(sk, f, id);
    final rem = hasLim ? _rem(sk, id) : -1; final lim = hasLim ? _lim(sk, id) : 0;
    final full = hasLim && !avail;
    final seatTxt = (!hasLim || lim <= 0) ? '' : full ? 'FULLY BOOKED' : '$rem / $lim seats left';
    final seatClr = full ? Colors.red : (rem > 0 && rem <= 5 ? Colors.orange : AppTheme.teal);

    return Opacity(opacity: full ? 0.4 : 1, child: RadioListTile<String>(
      value: id, groupValue: _sel[f] ?? '',
      onChanged: full ? null : (v) => setState(() => _sel[f] = v ?? ''),
      title: Text(name, style: TextStyle(fontSize: 14, color: full ? Colors.grey : null)),
      subtitle: seatTxt.isNotEmpty ? Padding(padding: const EdgeInsets.only(left: 28), child: Text(seatTxt, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: seatClr))) : null,
      dense: true, contentPadding: EdgeInsets.zero, activeColor: AppTheme.teal));
  }
}
