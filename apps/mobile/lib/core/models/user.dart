class User {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final String role; // ADMIN | EMPLOYEE
  final bool isActive;
  final String? profilePhoto;
  final String? designation;
  final DateTime? dateOfBirth;
  final DateTime dateOfJoining;
  final String? address;
  final String? emergencyName;
  final String? emergencyPhone;

  // Salary config
  final String salaryType; // MONTHLY | HOURLY
  final double? monthlySalary;
  final double? hourlyRate;
  final String? bankAccount;
  final String? bankIfsc;
  final String? upiId;

  // Leave balances
  final int sickLeaveBalance;
  final int casualLeaveBalance;
  final int paidLeaveBalance;

  // Shift config
  final String shiftStart;
  final String shiftEnd;
  final int graceMins;
  final List<int> weeklyOffDays;

  User({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    required this.role,
    this.isActive = true,
    this.profilePhoto,
    this.designation,
    this.dateOfBirth,
    required this.dateOfJoining,
    this.address,
    this.emergencyName,
    this.emergencyPhone,
    this.salaryType = 'MONTHLY',
    this.monthlySalary,
    this.hourlyRate,
    this.bankAccount,
    this.bankIfsc,
    this.upiId,
    this.sickLeaveBalance = 12,
    this.casualLeaveBalance = 12,
    this.paidLeaveBalance = 15,
    this.shiftStart = '09:00',
    this.shiftEnd = '18:00',
    this.graceMins = 15,
    this.weeklyOffDays = const [0],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      role: json['role'] as String,
      isActive: json['isActive'] as bool? ?? true,
      profilePhoto: json['profilePhoto'] as String?,
      designation: json['designation'] as String?,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'] as String)
          : null,
      dateOfJoining: json['dateOfJoining'] != null
          ? DateTime.parse(json['dateOfJoining'] as String)
          : DateTime.now(),
      address: json['address'] as String?,
      emergencyName: json['emergencyName'] as String?,
      emergencyPhone: json['emergencyPhone'] as String?,
      salaryType: json['salaryType'] as String? ?? 'MONTHLY',
      monthlySalary: (json['monthlySalary'] as num?)?.toDouble(),
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble(),
      bankAccount: json['bankAccount'] as String?,
      bankIfsc: json['bankIfsc'] as String?,
      upiId: json['upiId'] as String?,
      sickLeaveBalance: json['sickLeaveBalance'] as int? ?? 12,
      casualLeaveBalance: json['casualLeaveBalance'] as int? ?? 12,
      paidLeaveBalance: json['paidLeaveBalance'] as int? ?? 15,
      shiftStart: json['shiftStart'] as String? ?? '09:00',
      shiftEnd: json['shiftEnd'] as String? ?? '18:00',
      graceMins: json['graceMins'] as int? ?? 15,
      weeklyOffDays: (json['weeklyOffDays'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [0],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'role': role,
        'isActive': isActive,
        'profilePhoto': profilePhoto,
        'designation': designation,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'dateOfJoining': dateOfJoining.toIso8601String(),
        'address': address,
        'emergencyName': emergencyName,
        'emergencyPhone': emergencyPhone,
        'salaryType': salaryType,
        'monthlySalary': monthlySalary,
        'hourlyRate': hourlyRate,
        'bankAccount': bankAccount,
        'bankIfsc': bankIfsc,
        'upiId': upiId,
        'sickLeaveBalance': sickLeaveBalance,
        'casualLeaveBalance': casualLeaveBalance,
        'paidLeaveBalance': paidLeaveBalance,
        'shiftStart': shiftStart,
        'shiftEnd': shiftEnd,
        'graceMins': graceMins,
        'weeklyOffDays': weeklyOffDays,
      };
}
