/// Akun lokal untuk papan peringkat.
class UserProfile {
  const UserProfile({
    required this.email,
    required this.name,
    required this.pin,
  });

  final String email;
  final String name;
  final String pin;

  bool get isLoggedIn => email.contains('@') && pin.length >= 4;

  UserProfile copyWith({String? email, String? name, String? pin}) {
    return UserProfile(
      email: email ?? this.email,
      name: name ?? this.name,
      pin: pin ?? this.pin,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'email': email,
    'name': name,
    'pin': pin,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    email: (json['email'] as String?)?.trim() ?? '',
    name: (json['name'] as String?)?.trim() ?? '',
    pin: (json['pin'] as String?)?.trim() ?? '',
  );
}

/// Draf brief yang tersimpan supaya tidak hilang kalau app tertutup.
class DraftBrief {
  const DraftBrief({
    this.modeId = 'judul',
    this.brief = '',
    this.extra = '',
  });

  final String modeId;
  final String brief;
  final String extra;

  bool get isEmpty => brief.trim().isEmpty && extra.trim().isEmpty;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'modeId': modeId,
    'brief': brief,
    'extra': extra,
  };

  factory DraftBrief.fromJson(Map<String, dynamic> json) => DraftBrief(
    modeId: (json['modeId'] as String?) ?? 'judul',
    brief: (json['brief'] as String?) ?? '',
    extra: (json['extra'] as String?) ?? '',
  );
}
