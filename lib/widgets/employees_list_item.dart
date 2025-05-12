import 'package:empmanagement/models/employees.dart';
import 'package:flutter/material.dart';

class EmployeeListItem extends StatelessWidget {
  final Employee employee;
  final VoidCallback onTap;

  const EmployeeListItem({
    Key? key,
    required this.employee,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.purple.shade100,
          child: Icon(
            Icons.person_outline,
            color: Colors.purple,
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ตำแหน่ง:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              'ชื่อ: ${employee.firstName}',
              style: TextStyle(fontSize: 12),
            ),
            Text(
              'นามสกุล: ${employee.lastName}',
              style: TextStyle(fontSize: 12),
            ),
            Text(
              'เงินเดือน: ${employee.salary}',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.phone,
            color: Colors.green,
          ),
          onPressed: () {
            // ส่วนสำหรับการโทรไปยังพนักงาน (ถ้ามีการเพิ่มฟีเจอร์นี้ในอนาคต)
          },
        ),
        onTap: onTap, // เมื่อคลิกที่รายการจะไปยังหน้ารายละเอียด
      ),
    );
  }
}