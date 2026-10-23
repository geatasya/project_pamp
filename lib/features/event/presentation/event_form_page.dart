import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/layout/responsive.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/ui_kit.dart';
import '../../auth/presentation/auth_provider.dart';
import '../domain/event_entity.dart';
import 'event_provider.dart';
import 'widgets/event_card.dart';

class EventFormPage extends StatefulWidget {
  final EventEntity? event; // null = tambah, ada isi = edit
  const EventFormPage({super.key, this.event});
  @override
  State<EventFormPage> createState() => _EventFormPageState();
}

class _EventFormPageState extends State<EventFormPage> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _location;
  late final TextEditingController _address;
  late final TextEditingController _lineup;
  late final TextEditingController _desc;
  late final TextEditingController _ticketUrl;
  late final TextEditingController _price;
  late final TextEditingController _saved;
  late final TextEditingController _notes;
  late final TextEditingController _checklist;

  DateTime? _date;
  DateTime? _endDate;
  TimeOfDay? _start;
  TimeOfDay? _end;
  TimeOfDay? _door;
  String? _type;
  String? _tier;
  final Set<String> _genres = {};
  bool _visited = false;
  bool _fav = false;
  bool _submitted = false;

  String? _imageUrl;
  Uint8List? _bytes;
  String _ext = 'jpg';
  bool _saving = false;

  bool get _isEdit => widget.event != null;

  static const _venues = ['GBK Senayan', 'JIExpo', 'ICE BSD'];

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _name = TextEditingController(text: e?.name ?? '');
    _location = TextEditingController(text: e?.location ?? '');
    _address = TextEditingController(text: e?.address ?? '');
    _lineup = TextEditingController(text: e?.lineup ?? '');
    _desc = TextEditingController(text: e?.description ?? '');
    _ticketUrl = TextEditingController(text: e?.ticketUrl ?? '');
    _price = TextEditingController(text: e?.priceFrom?.toString() ?? '');
    _saved = TextEditingController(text: e?.savedAmount?.toString() ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
    _checklist = TextEditingController(text: e?.checklist ?? '');
    _date = e?.date;
    _endDate = e?.endDate;
    _start = _parseTime(e?.startTime);
    _end = _parseTime(e?.endTime);
    _door = _parseTime(e?.doorTime);
    _type = e?.eventType;
    _tier = e?.ticketTier;
    _genres.addAll(e?.genreList ?? const []);
    _visited = e?.isVisited ?? false;
    _fav = e?.isFavorite ?? false;
    _imageUrl = e?.imageUrl;
  }

  @override
  void dispose() {
    for (final c in [
      _name, _location, _address, _lineup, _desc, _ticketUrl, _price,
      _saved, _notes, _checklist
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ---------- helper ----------
  TimeOfDay? _parseTime(String? s) {
    if (s == null || !s.contains(':')) return null;
    final p = s.split(':');
    final h = int.tryParse(p[0]);
    final m = int.tryParse(p[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _fmtDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

  bool get _hasAdvanced =>
      _endDate != null ||
      _end != null ||
      _door != null ||
      _address.text.isNotEmpty ||
      _lineup.text.isNotEmpty ||
      _desc.text.isNotEmpty ||
      _ticketUrl.text.isNotEmpty ||
      _saved.text.isNotEmpty ||
      _checklist.text.isNotEmpty ||
      _visited;

  Future<void> _pickDate({required bool isEnd}) async {
    final first = isEnd ? (_date ?? DateTime(2020)) : DateTime(2020);
    var initial = isEnd
        ? (_endDate ?? _date ?? DateTime.now())
        : (_date ?? DateTime.now());
    if (initial.isBefore(first)) initial = first;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isEnd) {
        _endDate = picked;
      } else {
        _date = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) _endDate = null;
      }
    });
  }

  Future<void> _pickTime(TimeOfDay? cur, ValueChanged<TimeOfDay> set) async {
    final t = await showTimePicker(
      context: context,
      initialTime: cur ?? const TimeOfDay(hour: 19, minute: 0),
    );
    if (t != null) setState(() => set(t));
  }

  Future<void> _pickImage() async {
    final x = await ImagePicker().pickImage(
        source: ImageSource.gallery, maxWidth: 1600, imageQuality: 88);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    if (!mounted) return;
    if (bytes.length > 5 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ukuran gambar maksimal 5MB')));
      return;
    }
    final n = x.name.toLowerCase();
    final ext = n.contains('.') ? n.split('.').last : 'jpg';
    setState(() {
      _bytes = bytes;
      _ext = ['jpg', 'jpeg', 'png', 'webp'].contains(ext) ? ext : 'jpg';
    });
  }

  Future<void> _pasteUrl() async {
    final c = TextEditingController(text: _imageUrl ?? '');
    final res = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Tempel tautan gambar'),
        content: TextField(
          controller: c,
          autofocus: true,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(hintText: 'https://...'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(context, c.text.trim()),
              child: const Text('Pakai')),
        ],
      ),
    );
    c.dispose();
    if (res != null && res.isNotEmpty) {
      setState(() {
        _imageUrl = res;
        _bytes = null;
      });
    }
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    final valid = _form.currentState!.validate();
    if (!valid || _date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lengkapi data yang wajib diisi dulu')));
      return;
    }
    setState(() => _saving = true);
    final provider = context.read<EventProvider>();

    var imageUrl = _imageUrl;
    if (_bytes != null) {
      imageUrl = await provider.uploadPoster(_bytes!, _ext);
      if (imageUrl == null) {
        if (!mounted) return;
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(provider.error ?? 'Upload poster gagal')));
        return;
      }
    }

    var url = _ticketUrl.text.trim();
    if (url.isNotEmpty && !url.startsWith('http')) url = 'https://$url';

    final data = EventEntity(
      id: widget.event?.id,
      name: _name.text.trim(),
      date: _date!,
      endDate: _endDate,
      startTime: _start == null ? null : _fmtTime(_start!),
      endTime: _end == null ? null : _fmtTime(_end!),
      doorTime: _door == null ? null : _fmtTime(_door!),
      location: _location.text.trim(),
      address: _address.text,
      eventType: _type,
      category: eventGenres.where(_genres.contains).join(','),
      description: _desc.text,
      lineup: _lineup.text,
      ticketUrl: url,
      ticketTier: _tier,
      priceFrom: int.tryParse(_price.text.trim()),
      savedAmount: int.tryParse(_saved.text.trim()),
      notes: _notes.text,
      checklist: _checklist.text,
      imageUrl: imageUrl,
      isVisited: _visited,
      isFavorite: _fav,
    );
    final ok = await provider.saveEvent(data);
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Gagal menyimpan')));
    }
  }

  // ---------- potongan UI ----------
  Widget _label(IconData icon, String text,
          {String? trailing, Color trailingColor = AppColors.muted}) =>
      Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10),
        child: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(text,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            const Spacer(),
            if (trailing != null)
              Text(trailing,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: trailingColor)),
          ],
        ),
      );

  Widget _helper(String text, {IconData? icon}) => Padding(
        padding: const EdgeInsets.only(left: 6, top: 8),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: AppColors.muted),
              const SizedBox(width: 6),
            ],
            Expanded(
              child: Text(text,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ),
          ],
        ),
      );

  Widget _selPill(String label, bool sel, VoidCallback onTap,
      {bool check = false}) {
    return Material(
      color: sel ? AppColors.ink : AppColors.subtle,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (sel && check) ...[
                const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                const SizedBox(width: 6),
              ],
              Text(label,
                  style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: sel ? Colors.white : AppColors.ink)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _posterCard() {
    final has = _bytes != null || (_imageUrl?.isNotEmpty ?? false);
    return SoftCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (has) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 230,
                width: double.infinity,
                child: _bytes != null
                    ? Image.memory(_bytes!, fit: BoxFit.cover)
                    : EventPoster(url: _imageUrl),
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                  color: AppColors.subtle, shape: BoxShape.circle),
              child: const Icon(Icons.cloud_upload_outlined, size: 36),
            ),
            const SizedBox(height: 16),
            const Text('Unggah Visual Konser',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text(
              'Format JPG, PNG, WEBP hingga 5MB atau\npaste tautan gambar',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 18),
          ],
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
                  label: Text(has ? 'Ganti Berkas' : 'Pilih Berkas'),
                ),
              ),
              const SizedBox(width: 10),
              RoundIconButton(
                  icon: Icons.link_rounded,
                  size: 54,
                  bg: AppColors.subtle,
                  tooltip: 'Tempel tautan gambar',
                  onTap: _pasteUrl),
              if (has) ...[
                const SizedBox(width: 10),
                RoundIconButton(
                    icon: Icons.delete_outline_rounded,
                    size: 54,
                    fg: AppColors.red,
                    tooltip: 'Hapus poster',
                    onTap: () => setState(() {
                          _bytes = null;
                          _imageUrl = null;
                        })),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusRow() => Row(
        children: [
          const Pill('Supabase Active',
              dot: AppColors.green,
              bg: Colors.white,
              borderColor: AppColors.border,
              fg: AppColors.ink,
              fontSize: 12,
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 9)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                _seg('Tambah', !_isEdit),
                _seg('Edit', _isEdit),
              ],
            ),
          ),
        ],
      );

  Widget _seg(String t, bool sel) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? AppColors.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(t,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: sel ? Colors.white : AppColors.muted)),
      );

  List<Widget> _mainFields() {
    final tierText = _tier == null ? 'Pilih Tier' : 'Tier $_tier';
    return [
      _label(Icons.festival_outlined, 'Nama Event / Festival',
          trailing: '*Wajib', trailingColor: AppColors.red),
      TextFormField(
        controller: _name,
        textCapitalization: TextCapitalization.words,
        decoration:
            const InputDecoration(hintText: 'Contoh: Pestapora 2025'),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Nama event wajib diisi' : null,
      ),
      _helper('Gunakan nama resmi panggung atau tur konser.'),
      const SizedBox(height: 4),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label(Icons.calendar_today_outlined, 'Tanggal Konser'),
                _PickerField(
                  hint: 'dd/mm/yyyy',
                  value: _date == null ? null : _fmtDate(_date!),
                  icon: Icons.calendar_month_outlined,
                  errorText:
                      (_submitted && _date == null) ? 'Pilih tanggal' : null,
                  onTap: () => _pickDate(isEnd: false),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label(Icons.access_time_rounded, 'Jam Mulai'),
                _PickerField(
                  hint: '--:--',
                  value: _start == null ? null : _fmtTime(_start!),
                  icon: Icons.access_time_rounded,
                  onTap: () => _pickTime(_start, (t) => _start = t),
                ),
              ],
            ),
          ),
        ],
      ),
      _label(Icons.location_on_outlined, 'Lokasi & Venue'),
      TextFormField(
        controller: _location,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          hintText: 'Contoh: Gambir Expo Kemayoran, Jakarta Pusat',
          prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.muted),
        ),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Lokasi wajib diisi' : null,
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text('Cepat pilih:',
              style: TextStyle(
                  fontSize: 12,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600)),
          for (final v in _venues)
            ActionChip(
              label: Text(v),
              labelStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              backgroundColor: Colors.white,
              side: const BorderSide(color: AppColors.border),
              shape: const StadiumBorder(),
              onPressed: () => setState(() => _location.text = v),
            ),
        ],
      ),
      _label(Icons.category_outlined, 'Jenis Event'),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final t in eventTypes)
            _selPill(t, _type == t, () => setState(() => _type = _type == t ? null : t),
                check: true),
        ],
      ),
      _label(Icons.interests_outlined, 'Kategori / Genre',
          trailing: '${_genres.length} Dipilih'),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final g in eventGenres)
            _selPill(g, _genres.contains(g), () {
              setState(() {
                if (!_genres.add(g)) _genres.remove(g);
              });
            }, check: true),
        ],
      ),
      _label(Icons.confirmation_number_outlined, 'Perkiraan Harga Tiket Masuk'),
      TextFormField(
        controller: _price,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          hintText: '450000',
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: 20, right: 8),
            child: Center(
              widthFactor: 1,
              child: Text('Rp',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            ),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(left: 6, top: 8),
        child: Row(
          children: [
            const Expanded(
              child: Text('Estimasi per tiket early bird / presale',
                  style: TextStyle(fontSize: 12, color: AppColors.muted)),
            ),
            PopupMenuButton<String>(
              tooltip: 'Pilih tier tiket',
              color: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              onSelected: (v) => setState(() => _tier = v),
              itemBuilder: (_) => [
                for (final t in ticketTiers)
                  PopupMenuItem(
                      value: t,
                      child: Text(t,
                          style: const TextStyle(fontWeight: FontWeight.w700))),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.subtle,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(tierText,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w800)),
                    const Icon(Icons.arrow_drop_down_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      _label(Icons.edit_note_rounded, 'Catatan Rencana Pribadi',
          trailing: 'Wishlist'),
      TextFormField(
        controller: _notes,
        maxLines: 4,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
            hintText: 'Contoh: Standby di barikade jam 18:30!'),
      ),
      _helper('Hanya tersimpan di profil personal kamu.',
          icon: Icons.lock_outline_rounded),
      const SizedBox(height: 18),
      _advanced(),
    ];
  }

  Widget _advanced() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _hasAdvanced,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          collapsedShape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          title: const Text('Opsi Lanjutan',
              style: TextStyle(fontWeight: FontWeight.w800)),
          subtitle: const Text(
              'Tanggal selesai, alamat, line-up, link tiket, checklist',
              style: TextStyle(fontSize: 12, color: AppColors.muted)),
          children: [
            Row(
              children: [
                Expanded(
                  child: _PickerField(
                    label: 'Tanggal selesai',
                    value: _endDate == null ? null : _fmtDate(_endDate!),
                    icon: Icons.event_rounded,
                    onTap: () => _pickDate(isEnd: true),
                    onClear: _endDate == null
                        ? null
                        : () => setState(() => _endDate = null),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _PickerField(
                    label: 'Jam selesai',
                    value: _end == null ? null : _fmtTime(_end!),
                    icon: Icons.access_time_rounded,
                    onTap: () => _pickTime(_end, (t) => _end = t),
                    onClear:
                        _end == null ? null : () => setState(() => _end = null),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _PickerField(
              label: 'Pintu dibuka',
              value: _door == null ? null : _fmtTime(_door!),
              icon: Icons.meeting_room_outlined,
              onTap: () => _pickTime(_door, (t) => _door = t),
              onClear: _door == null ? null : () => setState(() => _door = null),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _address,
              decoration: const InputDecoration(
                  labelText: 'Alamat lengkap venue',
                  prefixIcon: Icon(Icons.map_outlined, color: AppColors.muted)),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _lineup,
              maxLines: 2,
              decoration: const InputDecoration(
                  labelText: 'Line-up (pisahkan dengan koma)',
                  hintText: 'Hindia, Feel Koplo, The Adams'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _desc,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Deskripsi event'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _ticketUrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                  labelText: 'Link beli tiket',
                  hintText: 'https://...',
                  prefixIcon: Icon(Icons.link_rounded, color: AppColors.muted)),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _saved,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                  labelText: 'Dana terkumpul (Rp)',
                  prefixIcon:
                      Icon(Icons.savings_outlined, color: AppColors.muted)),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _checklist,
              decoration: const InputDecoration(
                  labelText: 'Checklist bawaan (pisahkan dengan koma)',
                  hintText: 'Jas hujan, Tumbler, Powerbank'),
            ),
            const SizedBox(height: 6),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              title: const Text('Sudah dikunjungi',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              value: _visited,
              onChanged: (v) => setState(() => _visited = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _saveButtons() => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : const Icon(Icons.cloud_upload_outlined, size: 21),
            label: const Text('Simpan ke Database Supabase'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: const Text('Batal & Kembali'),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final wide = isWideLayout(context);
    final auth = context.watch<AuthProvider>();

    final Widget body;
    if (wide) {
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 340,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label(Icons.image_outlined, 'Poster / Flyer Konser',
                    trailing: 'Opsional'),
                _posterCard(),
              ],
            ),
          ),
          const SizedBox(width: 28),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _statusRow(),
                ..._mainFields(),
                const SizedBox(height: 24),
                _saveButtons(),
              ],
            ),
          ),
        ],
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _statusRow(),
          _label(Icons.image_outlined, 'Poster / Flyer Konser',
              trailing: 'Opsional'),
          _posterCard(),
          ..._mainFields(),
        ],
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 68,
        titleSpacing: 14,
        title: Row(
          children: [
            RoundIconButton(
                icon: Icons.arrow_back_rounded,
                size: 42,
                bordered: false,
                bg: AppColors.subtle,
                onTap: () => Navigator.pop(context)),
            const SizedBox(width: 12),
            const LogoMark(size: 34),
            const SizedBox(width: 10),
            Text(_isEdit ? 'Edit Event Konser' : 'Tambah Event Konser'),
          ],
        ),
        actions: [
          InitialAvatar(text: auth.email ?? '?', size: 42),
          const SizedBox(width: 16),
        ],
        bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1), child: Divider(height: 1)),
      ),
      bottomNavigationBar: wide
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SafeArea(top: false, child: _saveButtons()),
            ),
      body: Form(
        key: _form,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(wide ? 32 : 16, 16, wide ? 32 : 16, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: wide ? 1060 : 640),
              child: body,
            ),
          ),
        ),
      ),
    );
  }
}

/// Kolom pilih tanggal / jam (tap untuk memilih).
class _PickerField extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? value;
  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final String? errorText;
  const _PickerField({
    this.label,
    this.hint,
    required this.value,
    required this.icon,
    required this.onTap,
    this.onClear,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: InputDecorator(
        isEmpty: value == null,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          errorText: errorText,
          suffixIcon: onClear != null
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: onClear)
              : Icon(icon, size: 20, color: AppColors.ink),
        ),
        child: Text(value ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      ),
    );
  }
}
