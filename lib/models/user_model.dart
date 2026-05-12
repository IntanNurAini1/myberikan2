class UserModel {
  final String uid;
  final String nip;
  final String username;
  final String emailPemulihan;

  UserModel({
    required this.uid,
    required this.nip,
    required this.username,
    required this.emailPemulihan,
  });

  factory UserModel.fromMap(
    Map<String, dynamic> data,
  ) {
    return UserModel(
      uid: data['uid'] ?? '',
      nip: data['nip'] ?? '',
      username: data['username'] ?? '',
      emailPemulihan:
          data['email_pemulihan'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nip': nip,
      'username': username,
      'email_pemulihan': emailPemulihan,
    };
  }
}