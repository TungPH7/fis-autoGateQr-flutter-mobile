# Seed Data Instructions

## 1. Tạo Users trong Firebase Console

### Customer Account
Vào **Firebase Console > Authentication > Add User**:
- Email: `customer@test.com`
- Password: `123456`

### Guard Account
- Email: `guard@test.com`
- Password: `123456`

### Admin Account
- Email: `admin@test.com`
- Password: `123456`

## 2. Tạo User Documents trong Firestore

Vào **Firestore Console > users**, tạo documents với ID = UID của user vừa tạo:

### Customer Document
```json
{
  "uid": "<UID_TỪ_AUTH>",
  "email": "customer@test.com",
  "fullName": "Nguyen Van Customer",
  "phone": "0901234567",
  "role": "customer",
  "companyId": null,
  "companyName": "ABC Company",
  "status": "active",
  "createdAt": <TIMESTAMP>
}
```

### Guard Document
```json
{
  "uid": "<UID_TỪ_AUTH>",
  "email": "guard@test.com",
  "fullName": "Tran Van Guard",
  "phone": "0907654321",
  "role": "guard",
  "status": "active",
  "createdAt": <TIMESTAMP>
}
```

### Admin Document
```json
{
  "uid": "<UID_TỪ_AUTH>",
  "email": "admin@test.com",
  "fullName": "Le Van Admin",
  "phone": "0909999999",
  "role": "admin",
  "status": "active",
  "createdAt": <TIMESTAMP>
}
```

## 3. Tạo Gate trong Firestore

Vào **Firestore Console > gates**, tạo document:

```json
{
  "gateCode": "GATE_01",
  "gateName": "Cổng chính",
  "gateType": "both",
  "isActive": true,
  "assignedGuards": [],
  "createdAt": <TIMESTAMP>
}
```

## 4. Test Flow

1. Mở app, chọn **Customer App**
2. Đăng nhập với `customer@test.com` / `123456`
3. Thêm xe mới
4. Tạo đăng ký mới

5. Mở app khác (hoặc logout), chọn **Guard App**
6. Đăng nhập với `guard@test.com` / `123456`
7. Quét QR code từ registration đã tạo
8. Check-in/Check-out
