/// Information about a visitor
class VisitorInfo {
  /// Unique identifier for the visitor in your platform.
  /// If provided, this is used to identify the same visitor across different sessions.
  /// If not provided, a new anonymous visitor will be created.
  final String? platformOpenId;

  /// Full name of the visitor
  final String? name;

  /// Nickname of the visitor
  final String? nickname;

  /// URL to the visitor's avatar image
  final String? avatarUrl;

  /// Phone number of the visitor
  final String? phoneNumber;

  /// Email address of the visitor
  final String? email;

  /// Company name of the visitor
  final String? company;

  /// Job title of the visitor
  final String? jobTitle;

  /// Custom attributes as a map of key-value pairs
  final Map<String, String?>? customAttributes;

  const VisitorInfo({
    this.platformOpenId,
    this.name,
    this.nickname,
    this.avatarUrl,
    this.phoneNumber,
    this.email,
    this.company,
    this.jobTitle,
    this.customAttributes,
  });

  VisitorInfo copyWith({
    String? platformOpenId,
    String? name,
    String? nickname,
    String? avatarUrl,
    String? phoneNumber,
    String? email,
    String? company,
    String? jobTitle,
    Map<String, String?>? customAttributes,
  }) {
    return VisitorInfo(
      platformOpenId: platformOpenId ?? this.platformOpenId,
      name: name ?? this.name,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      company: company ?? this.company,
      jobTitle: jobTitle ?? this.jobTitle,
      customAttributes: customAttributes ?? this.customAttributes,
    );
  }

  Map<String, dynamic> toJson() => {
    if (platformOpenId != null) 'platform_open_id': platformOpenId,
    if (name != null) 'name': name,
    if (nickname != null) 'nickname': nickname,
    if (avatarUrl != null) 'avatar_url': avatarUrl,
    if (phoneNumber != null) 'phone_number': phoneNumber,
    if (email != null) 'email': email,
    if (company != null) 'company': company,
    if (jobTitle != null) 'job_title': jobTitle,
    if (customAttributes != null) 'custom_attributes': customAttributes,
  };
}

