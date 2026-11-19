import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../models/barengin_models.dart';
import '../state/session_controller.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/common_widgets.dart';

class EditActivityScreen extends StatefulWidget {
  const EditActivityScreen({super.key, required this.activity});
  final Activity activity;

  @override
  State<EditActivityScreen> createState() => _EditActivityScreenState();
}

class _EditActivityScreenState extends State<EditActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _venue;
  late final TextEditingController _address;
  late final TextEditingController _area;
  late final TextEditingController _city;
  late final TextEditingController _budget;
  late DateTime _startsAt;
  late DateTime _endsAt;
  late int _capacity;
  late int? _categoryId;
  late String _level;
  List<Category> _categories = [];
  bool _loadingCategories = true;
  bool _saving = false;

  int get _minimumCapacity => widget.activity.joinedCount.clamp(2, 15).toInt();

  @override
  void initState() {
    super.initState();
    final activity = widget.activity;
    _title = TextEditingController(text: activity.title);
    _description = TextEditingController(text: activity.description);
    _venue = TextEditingController(text: activity.venueName);
    _address = TextEditingController(text: activity.address);
    _area = TextEditingController(text: activity.area);
    _city = TextEditingController(text: activity.city);
    _budget = TextEditingController(text: activity.budgetAmount.toString());
    final now = DateTime.now();
    _startsAt = activity.startsAt ?? now.add(const Duration(days: 1));
    _endsAt = activity.endsAt ?? _startsAt.add(const Duration(hours: 2));
    _capacity = activity.capacity.clamp(_minimumCapacity, 15).toInt();
    _categoryId = activity.categoryId;
    _level = activity.participantLevel;
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
        if (_categoryId == null ||
            !categories.any((category) => category.id == _categoryId)) {
          _categoryId = categories.isNotEmpty ? categories.first.id : null;
        }
        _loadingCategories = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _loadingCategories = false);
        showAppMessage(context, 'Kategori gagal dimuat: $error', error: true);
      }
    }
  }

  Future<void> _pickDateTime(bool start) async {
    final current = start ? _startsAt : _endsAt;
    final now = DateTime.now();
    final initial = current.isBefore(now)
        ? now.add(const Duration(hours: 1))
        : current;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null || !mounted) return;
    final selected = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      if (start) {
        _startsAt = selected;
        if (!_endsAt.isAfter(_startsAt)) {
          _endsAt = _startsAt.add(const Duration(hours: 2));
        }
      } else {
        _endsAt = selected;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      showAppMessage(context, 'Pilih kategori aktivitas.', error: true);
      return;
    }
    if (!_startsAt.isAfter(DateTime.now()) || !_endsAt.isAfter(_startsAt)) {
      showAppMessage(
        context,
        'Jadwal harus di masa depan dan waktu selesai setelah waktu mulai.',
        error: true,
      );
      return;
    }
    final budget =
        int.tryParse(_budget.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    setState(() => _saving = true);
    try {
      await context
          .read<SessionController>()
          .updateActivity(widget.activity.id, {
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
            'capacity': _capacity,
            'budget_amount': budget,
            'currency': 'IDR',
          });
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted) showAppMessage(context, error.firstFieldError, error: true);
    } catch (error) {
      if (mounted) {
        showAppMessage(
          context,
          'Gagal memperbarui aktivitas: $error',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEdit =
        ['draft', 'published'].contains(widget.activity.status) &&
        (widget.activity.startsAt?.isAfter(DateTime.now()) ?? false);
    if (!canEdit) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit aktivitas')),
        body: const Center(
          child: Text('Aktivitas ini sudah tidak dapat diubah.'),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit aktivitas',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          children: [
            const Text(
              'Perbarui detail kegiatan',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Perubahan akan langsung disimpan pada aktivitas ini.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 20),
            _label('Judul aktivitas'),
            TextFormField(
              controller: _title,
              maxLength: 120,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Judul wajib diisi.' : null,
            ),
            const SizedBox(height: 14),
            _label('Deskripsi'),
            TextFormField(
              controller: _description,
              minLines: 3,
              maxLines: 5,
              validator: (v) => (v == null || v.trim().length < 10)
                  ? 'Deskripsi minimal 10 karakter.'
                  : null,
            ),
            const SizedBox(height: 14),
            _label('Kategori'),
            if (_loadingCategories)
              const LinearProgressIndicator()
            else if (_categories.isEmpty)
              const Text(
                'Kategori tidak tersedia. Periksa koneksi lalu coba lagi.',
                style: TextStyle(color: AppColors.danger, fontSize: 12),
              )
            else
              DropdownButtonFormField<int>(
                initialValue: _categoryId,
                items: _categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _categoryId = value),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            const SizedBox(height: 14),
            _label('Tingkat peserta'),
            DropdownButtonFormField<String>(
              initialValue: _level,
              items: const [
                DropdownMenuItem(value: 'beginner', child: Text('Pemula')),
                DropdownMenuItem(
                  value: 'all_levels',
                  child: Text('Semua level'),
                ),
                DropdownMenuItem(
                  value: 'experienced',
                  child: Text('Berpengalaman'),
                ),
              ],
              onChanged: (value) =>
                  setState(() => _level = value ?? 'all_levels'),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 14),
            _label('Jadwal'),
            _dateTile('Mulai', _startsAt, () => _pickDateTime(true)),
            const SizedBox(height: 8),
            _dateTile('Selesai', _endsAt, () => _pickDateTime(false)),
            const SizedBox(height: 14),
            _label('Nama tempat'),
            TextFormField(controller: _venue, validator: _required),
            const SizedBox(height: 14),
            _label('Alamat'),
            TextFormField(controller: _address, validator: _required),
            const SizedBox(height: 14),
            _label('Area / kecamatan'),
            TextFormField(controller: _area),
            const SizedBox(height: 14),
            _label('Kota'),
            TextFormField(controller: _city, validator: _required),
            const SizedBox(height: 14),
            _label('Kapasitas termasuk Host'),
            Row(
              children: [
                IconButton(
                  onPressed: _capacity > _minimumCapacity
                      ? () => setState(() => _capacity--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  '$_capacity orang',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                IconButton(
                  onPressed: _capacity < 15
                      ? () => setState(() => _capacity++)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            Text(
              'Minimal kapasitas mengikuti jumlah peserta aktif (${widget.activity.joinedCount} orang).',
              style: const TextStyle(fontSize: 10, color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            _label('Budget per orang (rupiah)'),
            TextFormField(
              controller: _budget,
              keyboardType: TextInputType.number,
              validator: (v) =>
                  (int.tryParse((v ?? '').replaceAll(RegExp(r'[^0-9]'), '')) ??
                          -1) <
                      0
                  ? 'Budget tidak valid.'
                  : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _saving || _loadingCategories || _categories.isEmpty
                  ? null
                  : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Menyimpan...' : 'Simpan perubahan'),
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Bagian ini wajib diisi.' : null;

  Widget _label(String value) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(
      value,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: AppColors.ink,
      ),
    ),
  );

  Widget _dateTile(String label, DateTime value, VoidCallback onTap) =>
      ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.line),
        ),
        title: Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
        subtitle: Text(
          '${formatDate(value)} · ${formatTime(value)}',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        trailing: const Icon(Icons.edit_calendar_outlined),
        onTap: onTap,
      );
}
