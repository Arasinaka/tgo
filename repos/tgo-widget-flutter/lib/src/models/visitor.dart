/// Visitor system information
class VisitorSystemInfo {
  final String? sourceDetail;
  final String? browser;
  final String? operatingSystem;
  final String? deviceType;
  final String? appVersion;

  const VisitorSystemInfo({
    this.sourceDetail,
    this.browser,
    this.operatingSystem,
    this.deviceType,
    this.appVersion,
  });

  Map<String, dynamic> toJson() => {
        if (sourceDetail != null) 'source_detail': sourceDetail,
        if (browser != null) 'browser': browser,
        if (operatingSystem != null) 'operating_system': operatingSystem,
        if (deviceType != null) 'device_type': deviceType,
        if (appVersion != null) 'app_version': appVersion,
      };
}

/// Visitor registration request
class VisitorRegisterRequest {
  final String platformApiKey;
  final String? platformOpenId;
  final String? name;
  final String? nickname;
  final String? avatarUrl;
  final String? phoneNumber;
  final String? email;
  final String? company;
  final String? jobTitle;
  final String? source;
  final String? note;
  final Map<String, String?>? customAttributes;
  final VisitorSystemInfo? systemInfo;
  final String? timezone;

  const VisitorRegisterRequest({
    required this.platformApiKey,
    this.platformOpenId,
    this.name,
    this.nickname,
    this.avatarUrl,
    this.phoneNumber,
    this.email,
    this.company,
    this.jobTitle,
    this.source,
    this.note,
    this.customAttributes,
    this.systemInfo,
    this.timezone,
  });

  Map<String, dynamic> toJson() => {
        'platform_api_key': platformApiKey,
        if (platformOpenId != null && platformOpenId!.isNotEmpty)
          'platform_open_id': platformOpenId,
        if (name != null) 'name': name,
        if (nickname != null) 'nickname': nickname,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (email != null) 'email': email,
        if (company != null) 'company': company,
        if (jobTitle != null) 'job_title': jobTitle,
        if (source != null) 'source': source,
        if (note != null) 'note': note,
        if (customAttributes != null) 'custom_attributes': customAttributes,
        if (systemInfo != null) 'system_info': systemInfo!.toJson(),
        if (timezone != null) 'timezone': timezone,
      };
}

/// Visitor registration response
class VisitorRegisterResponse {
  final String id;
  final String platformOpenId;
  final String projectId;
  final String platformId;
  final String createdAt;
  final String updatedAt;
  final String firstVisitTime;
  final String lastVisitTime;
  final String? lastOfflineTime;
  final bool isOnline;
  final String channelId;
  final int? channelType;
  final String? imToken;
  final String? name;
  final String? nickname;
  final String? avatarUrl;
  final String? phoneNumber;
  final String? email;
  final String? company;
  final String? jobTitle;
  final String? source;
  final String? note;
  final Map<String, String?>? customAttributes;

  const VisitorRegisterResponse({
    required this.id,
    required this.platformOpenId,
    required this.projectId,
    required this.platformId,
    required this.createdAt,
    required this.updatedAt,
    required this.firstVisitTime,
    required this.lastVisitTime,
    this.lastOfflineTime,
    required this.isOnline,
    required this.channelId,
    this.channelType,
    this.imToken,
    this.name,
    this.nickname,
    this.avatarUrl,
    this.phoneNumber,
    this.email,
    this.company,
    this.jobTitle,
    this.source,
    this.note,
    this.customAttributes,
  });

  factory VisitorRegisterResponse.fromJson(Map<String, dynamic> json) {
    return VisitorRegisterResponse(
      id: json['id'] as String,
      platformOpenId: json['platform_open_id'] as String,
      projectId: json['project_id'] as String,
      platformId: json['platform_id'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      firstVisitTime: json['first_visit_time'] as String,
      lastVisitTime: json['last_visit_time'] as String,
      lastOfflineTime: json['last_offline_time'] as String?,
      isOnline: json['is_online'] as bool? ?? false,
      channelId: json['channel_id'] as String,
      channelType: json['channel_type'] as int?,
      imToken: json['im_token'] as String?,
      name: json['name'] as String?,
      nickname: json['nickname'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      phoneNumber: json['phone_number'] as String?,
      email: json['email'] as String?,
      company: json['company'] as String?,
      jobTitle: json['job_title'] as String?,
      source: json['source'] as String?,
      note: json['note'] as String?,
      customAttributes: json['custom_attributes'] != null
          ? Map<String, String?>.from(json['custom_attributes'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'platform_open_id': platformOpenId,
        'project_id': projectId,
        'platform_id': platformId,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'first_visit_time': firstVisitTime,
        'last_visit_time': lastVisitTime,
        if (lastOfflineTime != null) 'last_offline_time': lastOfflineTime,
        'is_online': isOnline,
        'channel_id': channelId,
        if (channelType != null) 'channel_type': channelType,
        if (imToken != null) 'im_token': imToken,
        if (name != null) 'name': name,
        if (nickname != null) 'nickname': nickname,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (email != null) 'email': email,
        if (company != null) 'company': company,
        if (jobTitle != null) 'job_title': jobTitle,
        if (source != null) 'source': source,
        if (note != null) 'note': note,
        if (customAttributes != null) 'custom_attributes': customAttributes,
      };
}

/// Cached visitor data for local storage
class CachedVisitor {
  final String apiBase;
  final String platformApiKey;
  final String visitorId;
  final String platformOpenId;
  final String channelId;
  final int? channelType;
  final String? imToken;
  final String projectId;
  final String platformId;
  final String createdAt;
  final String updatedAt;
  final int? expiresAt;

  const CachedVisitor({
    required this.apiBase,
    required this.platformApiKey,
    required this.visitorId,
    required this.platformOpenId,
    required this.channelId,
    this.channelType,
    this.imToken,
    required this.projectId,
    required this.platformId,
    required this.createdAt,
    required this.updatedAt,
    this.expiresAt,
  });

  factory CachedVisitor.fromResponse(
    String apiBase,
    String platformApiKey,
    VisitorRegisterResponse response, {
    int? expiresAt,
  }) {
    return CachedVisitor(
      apiBase: apiBase,
      platformApiKey: platformApiKey,
      visitorId: response.id,
      platformOpenId: response.platformOpenId,
      channelId: response.channelId,
      channelType: response.channelType,
      imToken: response.imToken,
      projectId: response.projectId,
      platformId: response.platformId,
      createdAt: response.createdAt,
      updatedAt: response.updatedAt,
      expiresAt: expiresAt,
    );
  }

  factory CachedVisitor.fromJson(Map<String, dynamic> json) {
    return CachedVisitor(
      apiBase: json['apiBase'] as String,
      platformApiKey: json['platform_api_key'] as String,
      visitorId: json['visitor_id'] as String,
      platformOpenId: json['platform_open_id'] as String,
      channelId: json['channel_id'] as String,
      channelType: json['channel_type'] as int?,
      imToken: json['im_token'] as String?,
      projectId: json['project_id'] as String,
      platformId: json['platform_id'] as String,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
      expiresAt: json['expires_at'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'apiBase': apiBase,
        'platform_api_key': platformApiKey,
        'visitor_id': visitorId,
        'platform_open_id': platformOpenId,
        'channel_id': channelId,
        if (channelType != null) 'channel_type': channelType,
        if (imToken != null) 'im_token': imToken,
        'project_id': projectId,
        'platform_id': platformId,
        'created_at': createdAt,
        'updated_at': updatedAt,
        if (expiresAt != null) 'expires_at': expiresAt,
      };

  /// Get the UID for IM connection (visitor_id + '-vtr')
  String get imUid {
    return visitorId.endsWith('-vtr') ? visitorId : '$visitorId-vtr';
  }
}

/// Internal visitor cache metadata
class VisitorCacheInfo {
  final String apiBase;
  final String apiKey;
  final String? platformOpenId;

  VisitorCacheInfo({
    required this.apiBase,
    required this.apiKey,
    this.platformOpenId,
  });

  String get cacheKey {
    final baseUrl = apiBase.replaceAll(RegExp(r'https?://'), '').replaceAll('/', '_');
    final openId = platformOpenId ?? 'anonymous';
    return 'tgo_visitor_${baseUrl}_${apiKey}_$openId';
  }
}
