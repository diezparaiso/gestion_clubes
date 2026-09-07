class Sponsor {
  final String id;
  final String clubId;
  final String name;
  final String? logoUrl;
  final String? website;
  final String? contactEmail;
  final String? contactPhone;
  final DateTime contractStartDate;
  final DateTime contractEndDate;
  final double annualAmount;
  final String? benefits;
  final String status;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Sponsor({
    required this.id,
    required this.clubId,
    required this.name,
    required this.logoUrl,
    required this.website,
    required this.contactEmail,
    required this.contactPhone,
    required this.contractStartDate,
    required this.contractEndDate,
    required this.annualAmount,
    required this.benefits,
    required this.status,
    required this.isPublic,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Sponsor.fromJson(Map<String, dynamic> json) {
    return Sponsor(
      id: json['id'] as String,
      clubId: json['club_id'] as String,
      name: json['name'] as String,
      logoUrl: json['logo_url'] as String?,
      website: json['website'] as String?,
      contactEmail: json['contact_email'] as String?,
      contactPhone: json['contact_phone'] as String?,
      contractStartDate: DateTime.parse(json['contract_start_date'] as String),
      contractEndDate: DateTime.parse(json['contract_end_date'] as String),
      annualAmount: (json['annual_amount'] as num).toDouble(),
      benefits: json['benefits'] as String?,
      status: json['status'] as String,
      isPublic: json['is_public'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'club_id': clubId,
    'name': name,
    'logo_url': logoUrl,
    'website': website,
    'contact_email': contactEmail,
    'contact_phone': contactPhone,
    'contract_start_date': contractStartDate.toIso8601String().split('T')[0],
    'contract_end_date': contractEndDate.toIso8601String().split('T')[0],
    'annual_amount': annualAmount,
    'benefits': benefits,
    'status': status,
    'is_public': isPublic,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  bool get isActive => status == 'active';
  bool get isExpired => contractEndDate.isBefore(DateTime.now());
  bool get isUpcoming => contractStartDate.isAfter(DateTime.now());

  String get daysRemaining {
    final days = contractEndDate.difference(DateTime.now()).inDays;
    if (days < 0) return 'Vencido';
    if (days == 0) return 'Vence hoy';
    if (days == 1) return 'Vence mañana';
    return 'Vence en $days días';
  }

  Sponsor copyWith({
    String? id,
    String? clubId,
    String? name,
    String? logoUrl,
    String? website,
    String? contactEmail,
    String? contactPhone,
    DateTime? contractStartDate,
    DateTime? contractEndDate,
    double? annualAmount,
    String? benefits,
    String? status,
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Sponsor(
      id: id ?? this.id,
      clubId: clubId ?? this.clubId,
      name: name ?? this.name,
      logoUrl: logoUrl ?? this.logoUrl,
      website: website ?? this.website,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      contractStartDate: contractStartDate ?? this.contractStartDate,
      contractEndDate: contractEndDate ?? this.contractEndDate,
      annualAmount: annualAmount ?? this.annualAmount,
      benefits: benefits ?? this.benefits,
      status: status ?? this.status,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}