class Category {
  const Category({
    required this.id,
    required this.name,
    required this.slug,
    this.iconKey = '',
  });
  final int id;
  final String name;
  final String slug;
  final String iconKey;

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: _asInt(json['id']),
    name: (json['name'] ?? 'Kategori').toString(),
    slug: (json['slug'] ?? '').toString(),
    iconKey: (json['icon_key'] ?? '').toString(),
  );
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.username = '',
    this.displayName = '',
    this.bio = '',
    this.city = '',
    this.area = '',
    this.avatarUrl,
    this.interests = const [],
    this.createdAt,
  });

  final int id;
  final String name;
  final String email;
  final String username;
  final String displayName;
  final String bio;
  final String city;
  final String area;
  final String? avatarUrl;
  final List<Category> interests;
  final DateTime? createdAt;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    final profile = json['profile'] is Map
        ? Map<String, dynamic>.from(json['profile'])
        : <String, dynamic>{};
    final rawInterests = json['interests'] is List
        ? json['interests'] as List
        : const [];
    return AppUser(
      id: _asInt(json['id']),
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      displayName: (profile['display_name'] ?? json['name'] ?? '').toString(),
      bio: (profile['bio'] ?? '').toString(),
      city: (profile['city'] ?? '').toString(),
      area: (profile['area'] ?? '').toString(),
      avatarUrl: profile['avatar_url']?.toString(),
      interests: rawInterests
          .whereType<Map>()
          .map((e) => Category.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()),
    );
  }
}

class Activity {
  const Activity({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.capacity,
    required this.joinedCount,
    required this.availableSlots,
    required this.budgetAmount,
    required this.city,
    required this.venueName,
    required this.address,
    required this.area,
    required this.participantLevel,
    required this.isFavorited,
    this.startsAt,
    this.endsAt,
    this.hostId,
    this.hostName = 'Host Barengin',
    this.hostUsername = '',
    this.categoryId,
    this.categoryName = 'Aktivitas',
    this.categorySlug = '',
    this.coverImageUrl,
  });

  final int id;
  final String title;
  final String description;
  final String status;
  final int capacity;
  final int joinedCount;
  final int availableSlots;
  final int budgetAmount;
  final String city;
  final String venueName;
  final String address;
  final String area;
  final String participantLevel;
  final bool isFavorited;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final int? hostId;
  final String hostName;
  final String hostUsername;
  final int? categoryId;
  final String categoryName;
  final String categorySlug;
  final String? coverImageUrl;

  factory Activity.fromJson(Map<String, dynamic> json) {
    final venue = json['venue'] is Map
        ? Map<String, dynamic>.from(json['venue'])
        : <String, dynamic>{};
    final budget = json['budget'] is Map
        ? Map<String, dynamic>.from(json['budget'])
        : <String, dynamic>{};
    final host = json['host'] is Map
        ? Map<String, dynamic>.from(json['host'])
        : <String, dynamic>{};
    final hostProfile = host['profile'] is Map
        ? Map<String, dynamic>.from(host['profile'])
        : <String, dynamic>{};
    final category = json['category'] is Map
        ? Map<String, dynamic>.from(json['category'])
        : <String, dynamic>{};
    return Activity(
      id: _asInt(json['id']),
      title: (json['title'] ?? 'Aktivitas Barengin').toString(),
      description: (json['description'] ?? '').toString(),
      status: (json['status'] ?? 'published').toString(),
      capacity: _asInt(json['capacity']),
      joinedCount: _asInt(json['joined_count']),
      availableSlots: _asInt(json['available_slots']),
      budgetAmount: _asInt(budget['amount']),
      city: (venue['city'] ?? '').toString(),
      venueName: (venue['name'] ?? '').toString(),
      address: (venue['address'] ?? '').toString(),
      area: (venue['area'] ?? '').toString(),
      participantLevel: (json['participant_level'] ?? 'all_levels').toString(),
      isFavorited: json['is_favorited'] == true,
      startsAt: DateTime.tryParse(
        (json['starts_at'] ?? '').toString(),
      )?.toLocal(),
      endsAt: DateTime.tryParse((json['ends_at'] ?? '').toString())?.toLocal(),
      hostId: host['id'] == null ? null : _asInt(host['id']),
      hostName: (hostProfile['display_name'] ?? host['name'] ?? 'Host Barengin')
          .toString(),
      hostUsername: (host['username'] ?? '').toString(),
      categoryId: category['id'] == null ? null : _asInt(category['id']),
      categoryName: (category['name'] ?? 'Aktivitas').toString(),
      categorySlug: (category['slug'] ?? '').toString(),
      coverImageUrl: json['cover_image_url']?.toString(),
    );
  }
}

class JoinRequest {
  const JoinRequest({
    required this.id,
    required this.activityId,
    required this.status,
    this.message = '',
    this.userName = 'Pengguna',
    this.username = '',
    this.city = '',
    this.activityTitle = 'Aktivitas',
  });
  final int id;
  final int activityId;
  final String status;
  final String message;
  final String userName;
  final String username;
  final String city;
  final String activityTitle;

  factory JoinRequest.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'])
        : <String, dynamic>{};
    final profile = user['profile'] is Map
        ? Map<String, dynamic>.from(user['profile'])
        : <String, dynamic>{};
    final activity = json['activity'] is Map
        ? Map<String, dynamic>.from(json['activity'])
        : <String, dynamic>{};
    return JoinRequest(
      id: _asInt(json['id']),
      activityId: _asInt(json['activity_id']),
      status: (json['status'] ?? 'pending').toString(),
      message: (json['message'] ?? '').toString(),
      userName: (profile['display_name'] ?? user['name'] ?? 'Pengguna')
          .toString(),
      username: (user['username'] ?? '').toString(),
      city: (profile['city'] ?? '').toString(),
      activityTitle: (activity['title'] ?? 'Aktivitas').toString(),
    );
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
