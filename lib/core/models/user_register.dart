class UserRegister {
  final String username;
  final String email;
  final String password;
  final String? phoneNumber;
  final String? nickname;

  UserRegister({
    required this.username,
    required this.email,
    required this.password,
    this.phoneNumber,
    this.nickname,
  });

  Map<String, dynamic> toJson() {
    return {
      "username": username,
      "email": email,
      "password": password,
      "phone_number": phoneNumber,
      "nickname": nickname,
    };
  }
}
