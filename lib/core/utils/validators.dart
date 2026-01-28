class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email không được để trống';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email không hợp lệ';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mật khẩu không được để trống';
    }
    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Vui lòng xác nhận mật khẩu';
    }
    if (value != password) {
      return 'Mật khẩu không khớp';
    }
    return null;
  }

  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Trường này'} không được để trống';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Số điện thoại không được để trống';
    }
    final phoneRegex = RegExp(r'^(0|\+84)[0-9]{9,10}$');
    if (!phoneRegex.hasMatch(value.replaceAll(' ', ''))) {
      return 'Số điện thoại không hợp lệ';
    }
    return null;
  }

  static String? plateNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Biển số xe không được để trống';
    }
    // Vietnamese plate number format: XX-XXXXX or XX-XXXXXX
    final plateRegex = RegExp(r'^[0-9]{2}[A-Z]-[0-9]{4,5}(\.[0-9]{2})?$');
    final normalizedValue = value.toUpperCase().replaceAll(' ', '');
    if (!plateRegex.hasMatch(normalizedValue)) {
      return 'Biển số xe không hợp lệ (VD: 29A-12345)';
    }
    return null;
  }

  static String? idCard(String? value) {
    if (value == null || value.isEmpty) {
      return 'Số CMND/CCCD không được để trống';
    }
    // Vietnamese ID card: 9 or 12 digits
    final idRegex = RegExp(r'^[0-9]{9}$|^[0-9]{12}$');
    if (!idRegex.hasMatch(value.replaceAll(' ', ''))) {
      return 'Số CMND/CCCD không hợp lệ';
    }
    return null;
  }

  static String? driverLicense(String? value) {
    if (value == null || value.isEmpty) {
      return 'Số GPLX không được để trống';
    }
    if (value.length < 10 || value.length > 15) {
      return 'Số GPLX không hợp lệ';
    }
    return null;
  }
}