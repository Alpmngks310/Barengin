import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/api_client.dart';
import '../state/session_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});
  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _name = TextEditingController();
  final _displayName = TextEditingController();
  final _username = TextEditingController();
  final _bio = TextEditingController();
  final _city = TextEditingController();
  final _area = TextEditingController();
  final _picker = ImagePicker();
  final Set<int> _selected = {};
  List<dynamic> _categories = [];
  XFile? _avatar;
  Uint8List? _avatarBytes;
  bool _loading = true;
  bool _saving = false;
  String? _categoryError;

  @override
  void initState() {
    super.initState();
    final user = context.read<SessionController>().user;
    _name.text = user?.name ?? '';
    _displayName.text = user?.displayName ?? '';
    _username.text = user?.username ?? '';
    _bio.text = user?.bio ?? '';
    _city.text = user?.city ?? '';
    _area.text = user?.area ?? '';
    _selected.addAll(user?.interests.map((e) => e.id) ?? const <int>[]);
    _loadCategories();
  }

  @override
  void dispose() {
    _name.dispose();
    _displayName.dispose();
    _username.dispose();
    _bio.dispose();
    _city.dispose();
    _area.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loading = true;
      _categoryError = null;
    });

    try {
      final data = await context.read<SessionController>().getCategories();

      if (!mounted) return;

      setState(() {
        _categories = data;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _categoryError = error is ApiException
            ? error.firstFieldError
            : 'Gagal memuat kategori. Periksa koneksi internet.';
      });
    }
  }

  Future<void> _pickAvatar() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
      maxWidth: 1000,
    );
    if (file != null) {
      final bytes = await file.readAsBytes();
      if (mounted) {
        setState(() {
          _avatar = file;
          _avatarBytes = bytes;
        });
      }
    }
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _displayName.text.trim().isEmpty) {
      showAppMessage(
        context,
        'Nama lengkap dan nama tampilan wajib diisi.',
        error: true,
      );
      return;
    }

    final username = _username.text.trim();

    if (username.isNotEmpty &&
        !RegExp(
          r'^[\p{L}\p{M}\p{N}_-]{3,30}$',
          unicode: true,
        ).hasMatch(username)) {
      showAppMessage(
        context,
        'Username harus 3–30 karakter dan hanya menggunakan huruf, angka, underscore, atau tanda hubung.',
        error: true,
      );
      return;
    }

    if (_avatarBytes != null && _avatarBytes!.length > 5 * 1024 * 1024) {
      showAppMessage(context, 'Ukuran foto maksimal 5 MB.', error: true);
      return;
    }

    if (_selected.length < 3 || _selected.length > 6) {
      showAppMessage(context, 'Pilih 3 sampai 6 minat.', error: true);
      return;
    }

    setState(() => _saving = true);

    bool profileSaved = false;

    try {
      final session = context.read<SessionController>();

      final fields = <String, String>{
        'name': _name.text.trim(),
        'username': username,
        'display_name': _displayName.text.trim(),
        'bio': _bio.text.trim(),
        'city': _city.text.trim(),
        'area': _area.text.trim(),
        'country_code': 'ID',
      };

      if (_avatar != null) {
        await session.api.uploadAvatar(_avatar!, fields: fields);
        await session.reloadUser();
      } else {
        await session.updateProfile(fields);
      }

      profileSaved = true;

      await session.updateInterests(_selected.toList());

      if (!mounted) return;

      showAppMessage(context, 'Profil dan minat berhasil diperbarui.');
      Navigator.pop(context);
    } on ApiException catch (error) {
      if (!mounted) return;

      final message = profileSaved
          ? 'Profil berhasil diperbarui, tetapi minat gagal disimpan: ${error.firstFieldError}'
          : error.firstFieldError;

      showAppMessage(context, message, error: true);
    } catch (error) {
      if (!mounted) return;

      final message = profileSaved
          ? 'Profil berhasil diperbarui, tetapi minat gagal disimpan.'
          : 'Gagal memperbarui profil: $error';

      showAppMessage(context, message, error: true);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionController>().user;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit profil',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        children: [
          Center(
            child: Column(
              children: [
                Builder(
                  builder: (context) {
                    ImageProvider? image;
                    if (_avatarBytes != null) {
                      image = MemoryImage(_avatarBytes!);
                    } else if ((user?.avatarUrl ?? '').isNotEmpty) {
                      image = NetworkImage(user!.avatarUrl!);
                    }
                    return GestureDetector(
                      onTap: _pickAvatar,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 43,
                            backgroundColor: AppColors.sageLight,
                            backgroundImage: image,
                            child: image == null
                                ? Text(
                                    (user?.displayName.isNotEmpty == true
                                            ? user!.displayName[0]
                                            : 'B')
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: AppColors.forest,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 25,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 29,
                              height: 29,
                              decoration: BoxDecoration(
                                color: AppColors.forest,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ganti foto profil',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.sageDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 23),
          const _Label('Nama lengkap'),
          TextField(
            controller: _name,
            decoration: const InputDecoration(hintText: 'Nama kamu'),
          ),
          const SizedBox(height: 13),
          const _Label('Nama tampilan'),
          TextField(
            controller: _displayName,
            decoration: const InputDecoration(
              hintText: 'Nama yang ingin ditampilkan',
            ),
          ),
          const SizedBox(height: 13),
          const _Label('Username'),
          TextField(
            controller: _username,
            decoration: const InputDecoration(
              prefixText: '@ ',
              hintText: 'username',
            ),
          ),
          const SizedBox(height: 13),
          const _Label('Tentang saya'),
          TextField(
            controller: _bio,
            minLines: 3,
            maxLines: 4,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText: 'Ceritakan sedikit tentang dirimu...',
            ),
          ),
          const SizedBox(height: 13),
          const _Label('Kota'),
          TextField(
            controller: _city,
            decoration: const InputDecoration(hintText: 'Contoh: Bandung'),
          ),
          const SizedBox(height: 13),
          const _Label('Area'),
          TextField(
            controller: _area,
            decoration: const InputDecoration(hintText: 'Contoh: Dago'),
          ),
          const SizedBox(height: 24),
          const Text(
            'Minat kamu',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 17,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Pilih 3–6 kategori untuk membantu Barengin menampilkan aktivitas yang lebih relevan.',
            style: TextStyle(fontSize: 11, color: AppColors.muted, height: 1.4),
          ),
          const SizedBox(height: 13),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_categoryError != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _categoryError!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _loadCategories,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba lagi'),
                ),
              ],
            )
          else if (_categories.isEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Belum ada kategori yang tersedia.',
                  style: TextStyle(fontSize: 12),
                ),
                OutlinedButton.icon(
                  onPressed: _loadCategories,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Muat ulang'),
                ),
              ],
            )
          else
            Wrap(
              spacing: 9,
              runSpacing: 9,
              children: _categories.map((category) {
                final c = category;
                final selected = _selected.contains(c.id);

                return FilterChip(
                  label: Text(c.name),
                  selected: selected,
                  onSelected: (value) => setState(() {
                    if (value && _selected.length < 6) {
                      _selected.add(c.id);
                    } else {
                      _selected.remove(c.id);
                    }
                  }),
                );
              }).toList(),
            ),
          const SizedBox(height: 22),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Simpan perubahan'),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 12,
        color: AppColors.ink,
      ),
    ),
  );
}
