class Employee {
  final String? id;
  final String firstName;
  final String lastName;
  final DateTime birth;
  final String email;
  final String photo;
  final int salary;
  final DateTime date;
  final String phone;
  final String department;

  Employee({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.birth,
    required this.email,
    required this.photo,
    required this.date,
    required this.phone,
    required this.salary,
    required this.department,
  });

  // แปลงข้อมูล Employee เป็น Map สำหรับส่งไปยัง API
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'emp_id': id,
      'emp_firstname': firstName,
      'emp_lastname': lastName,
      'emp_birth': birth.toIso8601String(),
      'emp_email': email,
      'emp_photo': photo,
      'emp_date': date.toIso8601String(),
      'emp_phone': phone,
      'dep_id': department,
    };
  }

  // สร้าง Employee จาก Map ที่ได้จาก API
  factory Employee.fromMap(Map<String, dynamic> map) {
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          print('Error parsing date: $value');
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return Employee(
      id: map['emp_id']?.toString(),
      firstName: map['emp_firstname']?.toString() ?? '',
      lastName: map['emp_lastname']?.toString() ?? '',
      birth: parseDateTime(map['emp_birth']),
      email: map['emp_email']?.toString() ?? '',
      photo: map['emp_photo']?.toString() ?? '',
      date: parseDateTime(map['emp_date']),
      phone: map['emp_phone']?.toString() ?? '',
      salary: map['dep_salary'] != null ? int.tryParse(map['dep_salary'].toString()) ?? 0 : 0,
      department: map['dep_id']?.toString() ?? '',
    );
  }
}
