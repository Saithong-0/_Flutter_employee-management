// services/database_services.dart - บริการเชื่อมต่อกับ API backend
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/employees.dart';

class DatabaseService {
  // URL ของ API backend
  // เปลี่ยนเป็น IP หรือ domain ที่ถูกต้องในการใช้งานจริง
  static const String _baseUrl =
      'Your Url'; // สำหรับ Android Emulator
  // static const String _baseUrl = 'Your Url'; // สำหรับ iOS Simulator
  // static const String _baseUrl = 'Your Url'; // สำหรับ Production

  // สร้าง headers สำหรับคำขอ HTTP
  Map<String, String> _headers() {
    return {'Content-Type': 'application/json', 'Accept': 'application/json'};
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

  // ดึงข้อมูลพนักงานทั้งหมด พร้อมตัวกรองที่เป็นตัวเลือก
  Future<List<Employee>> getEmployees({
    String? searchTerm,
    String? department,
  }) async {
    try {
      // สร้าง query parameters สำหรับการกรอง
      final queryParams = <String, String>{};
      if (searchTerm != null && searchTerm.isNotEmpty) {
        queryParams['searchTerm'] = searchTerm;
      }
      if (department != null && department != 'All' && department.isNotEmpty) {
  queryParams['department'] = department;
}


      // สร้าง URL พร้อม query parameters
      final uri = Uri.parse(
        '$_baseUrl/employee',
      ).replace(queryParameters: queryParams);

      // ทำคำขอ HTTP
      final response = await http.get(uri, headers: _headers());
      final data = _handleResponse(response) as List<dynamic>;

      // แปลงข้อมูลเป็นรายการ Employee
      return data.map((item) => Employee.fromMap(item)).toList();
    } catch (e) {
      debugPrint('เกิดข้อผิดพลาดในการดึงข้อมูลพนักงาน: $e');
      throw Exception('ไม่สามารถดึงข้อมูลพนักงานได้: $e');
    }
  }

  // ดึงข้อมูลพนักงานตาม ID
  Future<Employee> getEmployeeById(String id) async {
    try {
      final uri = Uri.parse('$_baseUrl/employee/$id');
      final response = await http.get(uri, headers: _headers());
      final data = _handleResponse(response);

      return Employee.fromMap(data);
    } catch (e) {
      debugPrint('เกิดข้อผิดพลาดในการดึงข้อมูลพนักงานตาม ID: $e');
      throw Exception('ไม่สามารถดึงข้อมูลพนักงานได้: $e');
    }
  }

  // ดึงรายชื่อแผนกทั้งหมด
  Future<List<Map<String, dynamic>>> getDepartments() async {
    try {
      final uri = Uri.parse('$_baseUrl/department');
      final response = await http.get(uri, headers: _headers());
      final data = _handleResponse(response) as List<dynamic>;
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      debugPrint('เกิดข้อผิดพลาดในการดึงข้อมูลแผนก: $e');
      throw Exception('ไม่สามารถโหลดแผนกได้');
    }
  }

  // เพิ่มพนักงานใหม่
  Future<Employee> addEmployee(Employee employee) async {
  try {
    final uri = Uri.parse('$_baseUrl/employee');
    final body = {
      'emp_id': employee.id,
      'emp_firstname': employee.firstName,
      'emp_lastname': employee.lastName,
      'emp_birth': employee.birth.toIso8601String(),
      'emp_email': employee.email,
      'emp_photo': employee.photo,
      'emp_date': employee.date.toIso8601String(),
      'emp_phone': employee.phone,
      'dep_id': employee.department, // ส่ง dep_id แทนชื่อแผนก
    };

    final response = await http.post(
      uri,
      headers: _headers(),
      body: json.encode(body),
    );

    _handleResponse(response);
    return employee;
  } catch (e) {
    debugPrint('เกิดข้อผิดพลาดในการเพิ่มพนักงาน: $e');
    throw Exception('ไม่สามารถเพิ่มพนักงานได้: $e');
  }
}

  // อัปเดตข้อมูลพนักงานที่มีอยู่
  Future<Employee> updateEmployee(Employee employee) async {
    try {
      final uri = Uri.parse('$_baseUrl/employee/${employee.id}');
      final response = await http.put(
        uri,
        headers: _headers(),
        body: json.encode(employee.toMap()),
      );

      final data = _handleResponse(response);
      return Employee.fromMap(data);
    } catch (e) {
      debugPrint('เกิดข้อผิดพลาดในการอัปเดตพนักงาน: $e');
      throw Exception('ไม่สามารถอัปเดตพนักงานได้: $e');
    }
  }

  // ลบพนักงาน
  Future<void> deleteEmployee(String id) async {
    try {
      final uri = Uri.parse('$_baseUrl/employee/$id');
      final response = await http.delete(uri, headers: _headers());
      _handleResponse(response);
    } catch (e) {
      debugPrint('เกิดข้อผิดพลาดในการลบพนักงาน: $e');
      throw Exception('ไม่สามารถลบพนักงานได้: $e');
    }
  }
}
