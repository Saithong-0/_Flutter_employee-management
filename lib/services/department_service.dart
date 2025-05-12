// services/department_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class Department {
  final String id;
  final String title;
  final int salary;
  final String description;

  Department({
    required this.id,
    required this.title,
    required this.salary,
    required this.description,
  });

  factory Department.fromMap(Map<String, dynamic> map) {
    return Department(
      id: map['dep_id']?.toString() ?? '',
      title: map['dep_title']?.toString() ?? '',
      salary: map['dep_salary'] != null ? int.tryParse(map['dep_salary'].toString()) ?? 0 : 0,
      description: map['dep_des']?.toString() ?? '',
    );
  }
}

class DepartmentService {
  // URL ของ API backend
  // ใช้ URL เดียวกับใน database_service.dart
  static const String _baseUrl = 'http://10.0.2.2:3000/api'; // สำหรับ Android Emulator
  // static const String _baseUrl = 'http://localhost:3000/api'; // สำหรับ iOS Simulator

  // สร้าง headers สำหรับคำขอ HTTP
  Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  // จัดการ response และ errors จาก API
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // ถ้า response body ว่างเปล่า
      if (response.body.isEmpty) {
        return null;
      }
      return json.decode(response.body);
    } else {
      final errorData = json.decode(response.body);
      final errorMessage = errorData['error'] ?? 'เกิดข้อผิดพลาดจากเซิร์ฟเวอร์';
      throw Exception(errorMessage);
    }
  }

  // ดึงข้อมูลแผนกทั้งหมด
  Future<List<Department>> getDepartments() async {
    try {
      final uri = Uri.parse('$_baseUrl/department');
      final response = await http.get(uri, headers: _headers());
      final data = _handleResponse(response) as List<dynamic>;

      // แปลงข้อมูลเป็นรายการ Department
      return data.map((item) => Department.fromMap(item)).toList();
    } catch (e) {
      debugPrint('เกิดข้อผิดพลาดในการดึงข้อมูลแผนก: $e');
      throw Exception('ไม่สามารถดึงข้อมูลแผนกได้: $e');
    }
  }
}