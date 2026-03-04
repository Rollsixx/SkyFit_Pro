import 'package:hive/hive.dart';

@HiveType(typeId: 1)
class UserModel extends HiveObject {
  @HiveField(0)
  final String email;

  @HiveField(1)
  final List<int> passwordHash; // PBKDF2 output bytes

  @HiveField(2)
  final List<int> salt; // random bytes

  @HiveField(3)
  bool biometricsEnabled;

  @HiveField(4)
  bool hasLoggedInOnce;

  UserModel({
    required this.email,
    required this.passwordHash,
    required this.salt,
    this.biometricsEnabled = false,
    this.hasLoggedInOnce = false,
  });

  UserModel copyWith({
    bool? biometricsEnabled,
    bool? hasLoggedInOnce,
  }) {
    return UserModel(
      email: email,
      passwordHash: passwordHash,
      salt: salt,
      biometricsEnabled: biometricsEnabled ?? this.biometricsEnabled,
      hasLoggedInOnce: hasLoggedInOnce ?? this.hasLoggedInOnce,
    );
  }
}

/// Manual Hive adapter (NO build_runner needed).
class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 1;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (int i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      fields[key] = reader.read();
    }
    return UserModel(
      email: fields[0] as String,
      passwordHash: (fields[1] as List).cast<int>(),
      salt: (fields[2] as List).cast<int>(),
      biometricsEnabled: (fields[3] as bool?) ?? false,
      hasLoggedInOnce: (fields[4] as bool?) ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.email)
      ..writeByte(1)
      ..write(obj.passwordHash)
      ..writeByte(2)
      ..write(obj.salt)
      ..writeByte(3)
      ..write(obj.biometricsEnabled)
      ..writeByte(4)
      ..write(obj.hasLoggedInOnce);
  }
}