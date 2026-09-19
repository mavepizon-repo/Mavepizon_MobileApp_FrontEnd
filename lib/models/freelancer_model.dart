class FreelancerModel {
  final String id;
  final String name;
  final String yearOfPassing;
  final String experience;
  final String district;
  final String address;
  final String mobileNo;
  final String email;
  final String profile;
  final String resume;
  final String aadhaar;
  final List<String> techStackNames;

  FreelancerModel({
    required this.id,
    required this.name,
    this.yearOfPassing = '',
    this.experience = '',
    this.district = '',
    this.address = '',
    this.mobileNo = '',
    this.email = '',
    this.profile = '',
    this.resume = '',
    this.aadhaar = '',
    this.techStackNames = const [],
  });

  factory FreelancerModel.fromJson(Map<String, dynamic> j) {
    return FreelancerModel(
      id: j['id']?.toString() ?? '',
      name: j['name']?.toString() ?? '',
      yearOfPassing: j['yearOfPassing']?.toString() ?? '',
      experience: j['experience']?.toString() ?? '',
      district: j['district']?.toString() ?? '',
      address: j['address']?.toString() ?? '',
      mobileNo: j['mobileNo']?.toString() ?? '',
      email: j['email']?.toString() ?? '',
      profile: j['profile']?.toString() ?? '',
      resume: j['resume']?.toString() ?? '',
      aadhaar: j['aadhaar']?.toString() ?? '',
      techStackNames: (j['techStackNames'] as List? ?? [])
          .map((e) => e.toString())
          .toList(),
    );
  }

  String get initials =>
      name.isNotEmpty ? name.trim().split(' ').first[0].toUpperCase() : '?';
}
