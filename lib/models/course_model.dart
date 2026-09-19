class CourseModel {
  final String id,
      courseCode,
      batchId,
      courseName,
      description,
      duration,
      startDate,
      endDate,
      registrationStartDate,
      registrationEndDate,
      status,
      createdBy,
      category;
  final double totalFees, registrationFees;
  final int totalSeatsOnline,
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

  CourseModel({
    required this.id,
    required this.courseCode,
    required this.batchId,
    required this.courseName,
    required this.description,
    required this.duration,
    required this.startDate,
    required this.endDate,
    required this.registrationStartDate,
    required this.registrationEndDate,
    required this.status,
    required this.createdBy,
    this.category = '',
    required this.totalFees,
    required this.registrationFees,
    required this.totalSeatsOnline,
    required this.registeredSeatsOnline,
    required this.availableSeatsOnline,
    required this.totalSeatsOffline,
    required this.registeredSeatsOffline,
    required this.availableSeatsOffline,
    required this.totalSeatsTirunelveli,
    required this.registeredSeatsTirunelveli,
    required this.availableSeatsTirunelveli,
    required this.totalSeatsTisaiyanvilai,
    required this.registeredSeatsTisaiyanvilai,
    required this.availableSeatsTisaiyanvilai,
    this.zoomLink,
    this.locations = const [],
    this.active = true,
  });

  factory CourseModel.fromJson(Map<String, dynamic> j) => CourseModel(
        id: j['id']?.toString() ?? '',
        courseCode: j['courseCode'] ?? '',
        batchId: j['batchId'] ?? '',
        courseName: j['courseName'] ?? '',
        description: j['description'] ?? '',
        duration: j['duration'] ?? '',
        startDate: j['startDate']?.toString() ?? '',
        endDate: j['endDate']?.toString() ?? '',
        registrationStartDate:
            j['registrationStartDate']?.toString() ?? '',
        registrationEndDate:
            j['registrationEndDate']?.toString() ?? '',
        status: j['status'] ?? 'ACTIVE',
        createdBy: j['createdBy']?.toString() ?? '',
        category: j['category']?.toString() ?? '',
        totalFees: (j['totalFees'] ?? 0).toDouble(),
        registrationFees: (j['registrationFees'] ?? 0).toDouble(),
        totalSeatsOnline: j['totalSeatsOnline'] ?? 0,
        registeredSeatsOnline: j['registeredSeatsOnline'] ?? 0,
        availableSeatsOnline: j['availableSeatsOnline'] ?? 0,
        totalSeatsOffline: j['totalSeatsOffline'] ?? 0,
        registeredSeatsOffline: j['registeredSeatsOffline'] ?? 0,
        availableSeatsOffline: j['availableSeatsOffline'] ?? 0,
        totalSeatsTirunelveli: j['tirunelveliTotalSeats'] ?? j['totalSeatsTirunelveli'] ?? 0,
        registeredSeatsTirunelveli:
            j['tirunelveliRegisteredSeats'] ?? j['registeredSeatsTirunelveli'] ?? 0,
        availableSeatsTirunelveli:
            j['tirunelveliAvailableSeats'] ?? j['availableSeatsTirunelveli'] ?? 0,
        totalSeatsTisaiyanvilai: j['tisaiyanvilaiTotalSeats'] ?? j['totalSeatsTisaiyanvilai'] ?? 0,
        registeredSeatsTisaiyanvilai:
            j['tisaiyanvilaiRegisteredSeats'] ?? j['registeredSeatsTisaiyanvilai'] ?? 0,
        availableSeatsTisaiyanvilai:
            j['tisaiyanvilaiAvailableSeats'] ?? j['availableSeatsTisaiyanvilai'] ?? 0,
        zoomLink: j['zoomLink'],
        locations: j['locations'] is List
            ? (j['locations'] as List).map((e) => e.toString()).toList()
            : [],
        active: j['active'] ?? true,
      );
}
