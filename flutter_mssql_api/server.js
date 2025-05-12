const express = require('express');
const cors = require('cors');
const sql = require('mssql');
const bodyParser = require('body-parser');

const app = express();
const port = process.env.PORT || 3000;


app.use(cors());
app.use(bodyParser.json());


const dbConfig = {
  user: 'saithong',
  password: '123456',
  server: 'DESKTOP-3GCRNVU',
  database: 'Employee_Management',
  port: 1433,
  options: {
    encrypt: true,
    trustServerCertificate: true
  },
  pool: {
    max: 10,
    min: 0,
    idleTimeoutMillis: 30000
  }
};



// ฟังก์ชันเชื่อมต่อ database
async function connectToDatabase() {
  try {
    await sql.connect(dbConfig);
    console.log('เชื่อมต่อกับฐานข้อมูลสำเร็จ');
  } catch (err) {
    console.error('เกิดข้อผิดพลาดในการเชื่อมต่อฐานข้อมูล:', err);
  }
}
connectToDatabase();

// API Routes

// GET - ดึงข้อมูลพนักงานทั้งหมดพร้อมข้อมูลแผนก
app.get('/api/employee', async (req, res) => {
  try {
    const { department, searchTerm } = req.query;

    let query = `
      SELECT 
        e.emp_id, e.emp_firstname, e.emp_lastname, e.emp_birth, e.emp_email,
        e.emp_photo, e.emp_date, e.emp_phone,
        d.dep_id, d.dep_title, d.dep_salary, d.dep_des
      FROM employee e
      LEFT JOIN department d ON e.dep_id = d.dep_id
      WHERE 1=1
    `;

    const request = new sql.Request();

    // กรองตามแผนก
    if (department && department.toLowerCase() !== 'all') {
      query += ` AND e.dep_id = @dep_id`;
      request.input('dep_id', sql.VarChar(20), department);
    }

    // ค้นหาด้วยชื่อ
    if (searchTerm && searchTerm.trim() !== '') {
      query += ` AND (e.emp_firstname LIKE @search OR e.emp_lastname LIKE @search)`;
      request.input('search', sql.VarChar(100), `%${searchTerm}%`);
    }

    const result = await request.query(query);
    res.json(result.recordset);
  } catch (err) {
    console.error('เกิดข้อผิดพลาดในการดึงข้อมูลพนักงาน:', err);
    res.status(500).json({ error: 'ไม่สามารถดึงข้อมูลพนักงานได้', details: err.message });
  }
});


// GET - ดึงข้อมูลพนักงานตาม emp_id
app.get('/api/employee/:id', async (req, res) => {
  try {
    let { id } = req.params;

    if (!id || id.trim() === '') {
      return res.status(400).json({ error: 'emp_id ไม่ถูกต้อง' });
    }

    id = id.trim(); 

    const request = new sql.Request();
    request.input('emp_id', sql.VarChar(20), id);

    console.log('🔍 ค้นหาพนักงานด้วย emp_id:', id);

    const query = `
      SELECT 
        e.emp_id, e.emp_firstname, e.emp_lastname, e.emp_birth, e.emp_email,
        e.emp_photo, e.emp_date, e.emp_phone,
        d.dep_id, d.dep_title, d.dep_salary, d.dep_des
      FROM employee e
      LEFT JOIN department d ON e.dep_id = d.dep_id
      WHERE RTRIM(LTRIM(e.emp_id)) = @emp_id
    `;

    const result = await request.query(query);

    if (result.recordset.length > 0) {
      res.json(result.recordset[0]);
    } else {
      res.status(404).json({ error: 'ไม่พบข้อมูลพนักงาน' });
    }
  } catch (err) {
    console.error('เกิดข้อผิดพลาดในการดึงข้อมูลพนักงานตาม ID:', err);
    res.status(500).json({ error: 'ไม่สามารถดึงข้อมูลพนักงานได้', details: err.message });
  }
});



// POST - เพิ่มพนักงานใหม่
app.post('/api/employee', async (req, res) => {
  try {
    const {
      emp_firstname, emp_lastname, emp_birth,
      emp_email, emp_photo, emp_date, emp_phone, dep_id
    } = req.body;

     if (dep_id) {
      const depRequest = new sql.Request();
      depRequest.input('dep_id', sql.VarChar(20), dep_id);
      const depCheck = await depRequest.query('SELECT dep_id FROM department WHERE dep_id = @dep_id');
      
      if (depCheck.recordset.length === 0) {
        return res.status(400).json({ error: 'รหัสแผนกไม่มีอยู่ในระบบ' });
      }
    }

    const request = new sql.Request();
    request.input('emp_firstname', sql.VarChar(50), emp_firstname);
    request.input('emp_lastname', sql.VarChar(50), emp_lastname);
    request.input('emp_birth', sql.Date, new Date(emp_birth));
    request.input('emp_email', sql.VarChar(50), emp_email);
    request.input('emp_photo', sql.VarChar(sql.MAX), emp_photo || ''); // ป้องกัน null
    request.input('emp_date', sql.Date, new Date(emp_date || new Date()));
    request.input('emp_phone', sql.VarChar(20), emp_phone);
    request.input('dep_id', sql.VarChar(20), dep_id);

    console.log('Executing sp_AddEmployee with params:', {
      emp_firstname, emp_lastname, emp_birth, emp_email,
      emp_date, emp_phone, dep_id
    });

    const result = await request.execute('sp_AddEmployee');
    
    console.log('SP result:', result);
    
    if (result.recordset && result.recordset.length > 0) {
      const newId = result.recordset[0].emp_id;
      console.log('New employee ID:', newId);
      res.status(201).json({ message: 'เพิ่มพนักงานสำเร็จ', emp_id: newId });
    } else {
      console.error('SP did not return expected data');
      res.status(500).json({ error: 'ไม่สามารถสร้าง ID พนักงานได้' });
    }
  } catch (err) {
    console.error('เกิดข้อผิดพลาดในการเพิ่มพนักงาน:', err);
    res.status(500).json({ error: 'ไม่สามารถเพิ่มพนักงานได้', details: err.message });
  }
});

// PUT - อัปเดตข้อมูลพนักงาน
app.put('/api/employee/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const {
      emp_firstname, emp_lastname, emp_birth,
      emp_email, emp_photo, emp_date, emp_phone, dep_id
    } = req.body;

    const request = new sql.Request();
    request.input('emp_id', sql.VarChar(20), id);
    request.input('emp_firstname', sql.VarChar(50), emp_firstname);
    request.input('emp_lastname', sql.VarChar(50), emp_lastname);
    request.input('emp_birth', sql.Date, new Date(emp_birth));
    request.input('emp_email', sql.VarChar(50), emp_email);
    request.input('emp_photo', sql.VarChar(sql.MAX), emp_photo || '');
    request.input('emp_date', sql.Date, new Date(emp_date));
    request.input('emp_phone', sql.VarChar(20), emp_phone);
    request.input('dep_id', sql.VarChar(20), dep_id);

    const query = `
      UPDATE employee
      SET emp_firstname = @emp_firstname,
          emp_lastname = @emp_lastname,
          emp_birth = @emp_birth,
          emp_email = @emp_email,
          emp_photo = @emp_photo,
          emp_date = @emp_date,
          emp_phone = @emp_phone,
          dep_id = @dep_id
      WHERE emp_id = @emp_id
    `;
    const result = await request.query(query);
    console.log('Rows affected:', result.rowsAffected);

    res.json({ message: 'อัปเดตพนักงานสำเร็จ', emp_id: id });
  } catch (err) {
    console.error('เกิดข้อผิดพลาดในการอัปเดตพนักงาน:', err);
    res.status(500).json({ error: 'ไม่สามารถอัปเดตพนักงานได้', details: err.message });
  }
});


// DELETE - ลบพนักงาน พร้อมจัดเรียง emp_id ใหม่
app.delete('/api/employee/:id', async (req, res) => {
  try {
    const { id } = req.params;

    // ลบก่อน
    const delRequest = new sql.Request();
    delRequest.input('emp_id', sql.VarChar(20), id);
    await delRequest.query('DELETE FROM employee WHERE emp_id = @emp_id');

    // แล้วจัดเรียงใหม่
    const reorderRequest = new sql.Request();
    await reorderRequest.execute('sp_ReorderEmpIds');

    res.json({ message: 'ลบและจัดเรียง emp_id สำเร็จ' });
  } catch (err) {
    console.error('เกิดข้อผิดพลาด:', err);
    res.status(500).json({ error: 'ไม่สามารถลบหรือจัดเรียง emp_id ได้', details: err.message });
  }
});
/////////////////////////////////////////////////////////////////////////////////////////////

// GET - ดึงข้อมูลแผนกทั้งหมด
app.get('/api/department', async (req, res) => {
  try {
    const query = `SELECT dep_id, dep_title, dep_salary, dep_des FROM department`;
    const result = await sql.query(query);
    res.json(result.recordset);
  } catch (err) {
    console.error('เกิดข้อผิดพลาดในการดึงข้อมูลแผนก:', err);
    res.status(500).json({ error: 'ไม่สามารถดึงข้อมูลแผนกได้', details: err.message });
  }
});

// GET - ดึงข้อมูลแผนกตาม ID
app.get('/api/department/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const request = new sql.Request();
    request.input('dep_id', sql.VarChar(20), id);

    const query = `SELECT dep_id, dep_title, dep_salary, dep_des FROM department WHERE dep_id = @dep_id`;
    const result = await request.query(query);
    
    if (result.recordset.length > 0) {
      res.json(result.recordset[0]);
    } else {
      res.status(404).json({ error: 'ไม่พบข้อมูลแผนก' });
    }
  } catch (err) {
    console.error('เกิดข้อผิดพลาดในการดึงข้อมูลแผนกตาม ID:', err);
    res.status(500).json({ error: 'ไม่สามารถดึงข้อมูลแผนกได้', details: err.message });
  }
});

// เริ่มต้น Server
app.listen(port, () => {
  console.log(`Server กำลังทำงานที่ port ${port}`);
});


