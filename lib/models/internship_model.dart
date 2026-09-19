class InternshipModel {
  final String id,
      internshipCode,
      internshipName,
      description,
      duration,
      startDate,
      endDate,
      registrationStartDate,
      registrationEndDate,
      batchCode,
      trainerName,
      status,
      category,
      createdBy;
  final double fees, registrationFees;
  final int totalSeats,
      registeredSeats,
      availableSeats,
      totalSeatsOnline,
      registeredSeatsOnline,
      availableSeatsOnline,
      totalSeatsOffline,
      registeredSeatsOffline,
      availableSeatsOffline,
      totalSeatsTirunelveli,
      registeredSeatsTirunelveli,
      availableSeatsTirunelveli,
      totalSeatsTisaiyanvilai,
      registeredSeatsTisaiyanvilai,
      availableSeatsTisaiyanvilai;
  final String? zoomLink;
  final List<String> locations;
  final bool active;

  InternshipModel({
    required this.id,
    required this.internshipCode,
    required this.internshipName,
    required this.description,
    required this.duration,
    required this.startDate,
    required this.endDate,
    this.registrationStartDate = '',
    this.registrationEndDate = '',
    required this.batchCode,
    required this.trainerName,
    required this.status,
    this.category = '',
    this.createdBy = '',
    required this.fees,
    required this.registrationFees,
    this.totalSeats = 0,
    this.registeredSeats = 0,
    this.availableSeats = 0,
    required this.totalSeatsOnline,
    this.registeredSeatsOnline = 0,
    required this.availableSeatsOnline,
    required this.totalSeatsOffline,
    this.registeredSeatsOffline = 0,
    required this.availableSeatsOffline,
    this.totalSeatsTirunelveli = 0,
    this.registeredSeatsTirunelveli = 0,
    this.availableSeatsTirunelveli = 0,
    this.totalSeatsTisaiyanvilai = 0,
    this.registeredSeatsTisaiyanvilai = 0,
    this.availableSeatsTisaiyanvilai = 0,
    this.zoomLink,
    this.locations = const [],
    this.active = true,
  });

  // Internships reuse the shared course payload shape; map the JSON keys onto
  // the existing InternshipModel property names so the UI keeps working.
  factory InternshipModel.fromJson(Map<String, dynamic> j) {
    final id = j['id']?.toString() ?? j['_id']?.toString() ?? '';
    final totalSeatsOnline = _int(j['totalSeatsOnline']);
    final totalSeatsOffline = _int(j['totalSeatsOffline']);
    final registeredSeatsOnline = _int(j['registeredSeatsOnline']);
    final registeredSeatsOffline = _int(j['registeredSeatsOffline']);

    return InternshipModel(
      id: id,
      internshipCode: (j['courseCode'] ?? j['internshipCode'] ?? '').toString(),
      internshipName:
          (j['courseName'] ?? j['internshipName'] ?? '').toString(),
      description: (j['description'] ?? '').toString(),
      duration: (j['duration'] ?? '').toString(),
      startDate: (j['startDate'] ?? '').toString(),
      endDate: (j['endDate'] ?? '').toString(),
      registrationStartDate: (j['registrationStartDate'] ?? '').toString(),
      registrationEndDate: (j['registrationEndDate'] ?? '').toString(),
      batchCode: (j['batchId'] ?? j['batchCode'] ?? '').toString(),
      trainerName:
          (j['trainerName'] ?? j['createdBy'] ?? '').toString(),
      status: (j['status'] ?? 'ACTIVE').toString(),
      category: (j['category']?.toString() ?? '').toString(),
      createdBy: (j['createdBy']?.toString() ?? '').toString(),
      fees: _double(j['totalFees'] ?? j['fees']),
      registrationFees: _double(j['registrationFees']),
      totalSeats: totalSeatsOnline + totalSeatsOffline,
      registeredSeats: registeredSeatsOnline + registeredSeatsOffline,
      availableSeats:
          _int(j['availableSeatsOnline']) + _int(j['availableSeatsOffline']),
      totalSeatsOnline: totalSeatsOnline,
      registeredSeatsOnline: registeredSeatsOnline,
      availableSeatsOnline: _int(j['availableSeatsOnline']),
      totalSeatsOffline: totalSeatsOffline,
      registeredSeatsOffline: registeredSeatsOffline,
      availableSeatsOffline: _int(j['availableSeatsOffline']),
      totalSeatsTirunelveli: _int(j['totalSeatsTirunelveli']),
      registeredSeatsTirunelveli: _int(j['registeredSeatsTirunelveli']),
      availableSeatsTirunelveli: _int(j['availableSeatsTirunelveli']),
      totalSeatsTisaiyanvilai: _int(j['totalSeatsTisaiyanvilai']),
      registeredSeatsTisaiyanvilai: _int(j['registeredSeatsTisaiyanvilai']),
      availableSeatsTisaiyanvilai: _int(j['availableSeatsTisaiyanvilai']),
      zoomLink: j['zoomLink'] is String ? j['zoomLink'] as String : null,
      locations: j['locations'] is List
          ? (j['locations'] as List).map((e) => e.toString()).toList()
          : [],
      active: j['active'] ?? (j['status']?.toString().toUpperCase() == 'ACTIVE'),
    );
  }

  static int _int(dynamic v) =>
      v is num ? v.toInt() : int.tryParse(v?.toString() ?? '') ?? 0;

  static double _double(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;
}