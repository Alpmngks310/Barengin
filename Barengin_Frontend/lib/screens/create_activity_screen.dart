import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../core/location_service.dart';
import '../models/barengin_models.dart';
import '../state/session_controller.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';

class CreateActivityScreen extends StatefulWidget {
  const CreateActivityScreen({super.key, this.onCreated});
  final VoidCallback? onCreated;
  @override
  State<CreateActivityScreen> createState() => _CreateActivityScreenState();
}

class _CreateActivityScreenState extends State<CreateActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _venue = TextEditingController();
  final _address = TextEditingController();
  final _area = TextEditingController();
  final _city = TextEditingController();
  final _budget = TextEditingController(text: '0');
  List<Category> _categories = [];
  int? _categoryId;
  String _level = 'all_levels';
  int _capacity = 5;
  int _step = 0;
  bool _loadingCategories = true;
  bool _submitting = false;
  bool _locating = false;
  double? _latitude;
  double? _longitude;
  late DateTime _startsAt;
  late DateTime _endsAt;

  @override
  void initState() {
    super.initState();
    final user = context.read<SessionController>().user;
    _area.text = user?.area ?? '';
    _city.text = user?.city ?? '';
    final now = DateTime.now();
    _startsAt = DateTime(now.year, now.month, now.day + 1, 15);
    _endsAt = DateTime(now.year, now.month, now.day + 1, 17);
    _loadCategories();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _venue.dispose();
    _address.dispose();
    _area.dispose();
    _city.dispose();
    _budget.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await context
          .read<SessionController>()
          .getCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _categoryId = categories.isNotEmpty ? categories.first.id : null;
        _loadingCategories = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final position = await LocationService.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
      showAppMessage(context, 'Koordinat GPS ditambahkan ke aktivitas ini.');
    } catch (error) {
      if (mounted) {
        showAppMessage(
          context,
          error.toString().replaceFirst('Exception: ', ''),
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _pickDateTime(bool isStart) async {
    final current = isStart ? _startsAt : _endsAt;
    final date = await showDatePicker(
      context: context,
      initialDate: current.isBefore(DateTime.now())
          ? DateTime.now().add(const Duration(days: 1))
          : current,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null || !mounted) return;
    final value = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      if (isStart) {
        _startsAt = value;
        if (!_endsAt.isAfter(_startsAt)) {
          _endsAt = _startsAt.add(const Duration(hours: 2));
        }
      } else {
        _endsAt = value;
      }
    });
  }

  void _next() {
    if (_step == 0) {
      if (!_formKey.currentState!.validate()) return;
      if (_categoryId == null) {
        showAppMessage(
          context,
          'Pilih kategori aktivitas terlebih dahulu.',
          error: true,
        );
        return;
      }
      if (!_startsAt.isAfter(DateTime.now()) || !_endsAt.isAfter(_startsAt)) {
        showAppMessage(
          context,
          'Pastikan waktu selesai setelah waktu mulai dan jadwal masih di masa depan.',
          error: true,
        );
        return;
      }
      setState(() => _step = 1);
    } else {
      if (!_formKey.currentState!.validate()) return;
      _reviewAndPublish();
    }
  }

  Future<void> _reviewAndPublish() async {
    final budget =
        int.tryParse(_budget.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Tinjau aktivitas',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 21,
                color: AppColors.ink,
              ),
            ),
            const Text(
              'Pastikan semua detail sudah benar sebelum dipublikasikan.',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 18),
            Text(
              _title.text,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.forest,
              ),
            ),
            const SizedBox(height: 12),
            _ReviewRow(label: 'Kategori', value: _selectedCategoryName),
            _ReviewRow(
              label: 'Jadwal',
              value:
                  '${formatDate(_startsAt)} · ${formatTime(_startsAt)}–${formatTime(_endsAt)}',
            ),
            _ReviewRow(
              label: 'Lokasi',
              value: '${_venue.text}, ${_area.text}, ${_city.text}',
            ),
            _ReviewRow(
              label: 'Peserta',
              value: '$_capacity orang (termasuk Host)',
            ),
            _ReviewRow(label: 'Budget', value: formatRupiah(budget)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.sageLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Dengan mempublikasikan, aktivitas akan terlihat oleh pengguna lain dan mereka dapat mengirim permintaan bergabung.',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.45,
                  color: AppColors.forest,
                ),
              ),
            ),
            const SizedBox(height: 17),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Publikasikan aktivitas'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Periksa lagi'),
              ),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true) return;
    setState(() => _submitting = true);
    try {
      final body = <String, dynamic>{
        'category_id': _categoryId,
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'participant_level': _level,
        'starts_at': isoWithOffset(_startsAt),
        'ends_at': isoWithOffset(_endsAt),
        'timezone': 'Asia/Jakarta',
        'venue_name': _venue.text.trim(),
        'address': _address.text.trim(),
        'area': _area.text.trim(),
        'city': _city.text.trim(),
        'province': 'Jawa Barat',
        'country_code': 'ID',
        'capacity': _capacity,
        'budget_amount': budget,
        'currency': 'IDR',
        if (_latitude != null && _longitude != null) 'latitude': _latitude,
        if (_latitude != null && _longitude != null) 'longitude': _longitude,
      };
      final created = await context.read<SessionController>().createActivity(
        body,
      );
      final id = int.tryParse(created['id'].toString());
      if (id == null) {
        throw ApiException('Aktivitas tersimpan tetapi ID tidak ditemukan.');
      }
      await context.read<SessionController>().publishActivity(id);
      if (!mounted) return;
      showAppMessage(
        context,
        'Aktivitas berhasil dipublikasikan. Saatnya cari teman bareng!',
      );
      widget.onCreated?.call();
    } on ApiException catch (e) {
      if (mounted) showAppMessage(context, e.firstFieldError, error: true);
    } catch (e) {
      if (mounted) {
        showAppMessage(
          context,
          'Aktivitas belum berhasil dipublikasikan: $e',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String get _selectedCategoryName {
    for (final category in _categories) {
      if (category.id == _categoryId) return category.name;
    }
    return 'Aktivitas';
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(
        'Buat aktivitas',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
      actions: [
        TextButton(
          onPressed: _step == 0 ? null : () => setState(() => _step = 0),
          child: const Text('Kembali'),
        ),
      ],
    ),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        children: [
          Row(
            children: [
              Text(
                '${_step + 1} dari 2',
                style: const TextStyle(
                  color: AppColors.sageDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                _step == 0 ? 'Mulai dari hal dasar' : 'Atur lokasi & peserta',
                style: const TextStyle(color: AppColors.muted, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _step == 0 ? .5 : 1,
              minHeight: 6,
              backgroundColor: AppColors.line,
              color: AppColors.sage,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            _step == 0 ? 'Apa yang mau kamu adakan?' : 'Bikin detailnya jelas',
            style: const TextStyle(
              fontSize: 24,
              letterSpacing: -.7,
              fontWeight: FontWeight.w900,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _step == 0
                ? 'Ceritakan aktivitasnya. Nanti orang lain bisa menemukan dan ikut.'
                : 'Lengkapi tempat, kuota, dan budget supaya calon peserta punya ekspektasi yang sama.',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 12,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 21),
          if (_step == 0) ...[
            const _FieldLabel('Nama aktivitas'),
            TextFormField(
              controller: _title,
              maxLength: 120,
              decoration: const InputDecoration(
                hintText: 'Contoh: Badminton santai bareng',
              ),
              validator: (v) => v == null || v.trim().length < 4
                  ? 'Judul minimal 4 karakter.'
                  : null,
            ),
            const SizedBox(height: 14),
            const _FieldLabel('Kategori'),
            if (_loadingCategories)
              const LinearProgressIndicator()
            else
              DropdownButtonFormField<int>(
                initialValue: _categoryId,
                decoration: const InputDecoration(hintText: 'Pilih kategori'),
                items: _categories
                    .map(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _categoryId = value),
              ),
            const SizedBox(height: 14),
            const _FieldLabel('Deskripsi'),
            TextFormField(
              controller: _description,
              minLines: 4,
              maxLines: 5,
              maxLength: 1000,
              decoration: const InputDecoration(
                hintText:
                    'Jelaskan kegiatan, level pengalaman, dan hal yang perlu dibawa...',
              ),
              validator: (v) => v == null || v.trim().length < 10
                  ? 'Deskripsi minimal 10 karakter.'
                  : null,
            ),
            const SizedBox(height: 12),
            const _FieldLabel('Level peserta'),
            Wrap(
              spacing: 8,
              children: [
                _ChoiceChip(
                  label: 'Pemula',
                  selected: _level == 'beginner',
                  onTap: () => setState(() => _level = 'beginner'),
                ),
                _ChoiceChip(
                  label: 'Semua level',
                  selected: _level == 'all_levels',
                  onTap: () => setState(() => _level = 'all_levels'),
                ),
                _ChoiceChip(
                  label: 'Berpengalaman',
                  selected: _level == 'experienced',
                  onTap: () => setState(() => _level = 'experienced'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const _FieldLabel('Jadwal kegiatan'),
            _DateTimePickerTile(
              label: 'Mulai',
              value: '${formatDate(_startsAt)} · ${formatTime(_startsAt)}',
              onTap: () => _pickDateTime(true),
            ),
            const SizedBox(height: 8),
            _DateTimePickerTile(
              label: 'Selesai',
              value: '${formatDate(_endsAt)} · ${formatTime(_endsAt)}',
              onTap: () => _pickDateTime(false),
            ),
          ] else ...[
            const _FieldLabel('Nama tempat'),
            TextFormField(
              controller: _venue,
              decoration: const InputDecoration(hintText: 'Contoh: GOR Dago'),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Nama tempat wajib diisi.'
                  : null,
            ),
            const SizedBox(height: 14),
            const _FieldLabel('Alamat lengkap'),
            TextFormField(
              controller: _address,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Jalan, nomor, patokan lokasi',
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Alamat wajib diisi.' : null,
            ),
            const SizedBox(height: 14),
            const _FieldLabel('Area / Kecamatan'),
            TextFormField(
              controller: _area,
              decoration: const InputDecoration(hintText: 'Contoh: Dago'),
            ),
            const SizedBox(height: 14),
            const _FieldLabel('Kota'),
            TextFormField(
              controller: _city,
              decoration: const InputDecoration(hintText: 'Contoh: Bandung'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Kota wajib diisi.' : null,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _locating ? null : _useCurrentLocation,
              icon: _locating
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_rounded, size: 18),
              label: Text(
                _latitude == null
                    ? 'Tambahkan koordinat GPS (opsional)'
                    : 'Koordinat GPS sudah ditambahkan',
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'GPS hanya digunakan untuk titik aktivitas ini. Kota dan alamat tetap bisa diisi manual.',
              style: TextStyle(fontSize: 10, color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            const _FieldLabel('Jumlah peserta (termasuk Host)'),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Kapasitas grup',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _capacity > 2
                        ? () => setState(() => _capacity--)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                  ),
                  Text(
                    '$_capacity',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  IconButton(
                    onPressed: _capacity < 15
                        ? () => setState(() => _capacity++)
                        : null,
                    icon: const Icon(Icons.add_circle_outline_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'MVP Barengin mendukung 2–15 orang. Host dihitung sebagai peserta pertama.',
              style: TextStyle(fontSize: 10, color: AppColors.muted),
            ),
            const SizedBox(height: 15),
            const _FieldLabel('Budget per orang (rupiah)'),
            TextFormField(
              controller: _budget,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '0 untuk gratis',
                prefixText: 'Rp ',
              ),
              validator: (v) =>
                  (int.tryParse((v ?? '').replaceAll(RegExp(r'[^0-9]'), '')) ??
                          -1) <
                      0
                  ? 'Masukkan angka budget yang valid.'
                  : null,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.lemon.withValues(alpha: .55),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline_rounded,
                    color: AppColors.forest,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Pilih titik pertemuan yang aman, mudah ditemukan, dan nyaman untuk semua peserta.',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.forest,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 25),
          ElevatedButton(
            onPressed: _submitting ? null : _next,
            child: _submitting
                ? const CircularProgressIndicator(color: Colors.white)
                : Text(
                    _step == 0
                        ? 'Lanjut: lokasi & peserta'
                        : 'Tinjau & publikasikan',
                  ),
          ),
          const SizedBox(height: 8),
          if (_step == 1)
            TextButton(
              onPressed: () => setState(() => _step = 0),
              child: const Text('Kembali ke informasi dasar'),
            ),
        ],
      ),
    ),
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
      ),
    ),
  );
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ChoiceChip(
    label: Text(label),
    selected: selected,
    onSelected: (_) => onTap(),
  );
}

class _DateTimePickerTile extends StatelessWidget {
  const _DateTimePickerTile({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final String value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            color: AppColors.sageDark,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.edit_outlined, color: AppColors.muted, size: 17),
        ],
      ),
    ),
  );
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 76,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    ),
  );
}
