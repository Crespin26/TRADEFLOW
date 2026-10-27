class CompanyProfile {
  const CompanyProfile({
    this.name = '',
    this.address = '',
    this.country = '',
    this.email = '',
    this.phone = '',
    this.registration = '',
    this.revision = 0,
  });
  final String name, address, country, email, phone, registration;
  final int revision;
  Map<String, dynamic> toJson() => {
    'name': name,
    'address': address,
    'country': country,
    'email': email,
    'phone': phone,
    'registration': registration,
    'revision': revision,
  };
  factory CompanyProfile.fromJson(Map<String, dynamic> j) => CompanyProfile(
    name: j['name'] as String,
    address: j['address'] as String,
    country: j['country'] as String,
    email: j['email'] as String,
    phone: j['phone'] as String,
    registration: j['registration'] as String,
    revision: j['revision'] as int,
  );
}
