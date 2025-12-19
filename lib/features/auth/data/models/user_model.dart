import 'package:json_annotation/json_annotation.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final int id;
  final String phone;
  final String? email;
  final String? firstName;
  final String? surname;
  final String? gender;
  final String? region;
  final String? avatar;
  final bool? isVerified;

  UserModel({
    required this.id,
    required this.phone,
    this.email,
    this.firstName,
    this.surname,
    this.gender,
    this.region,
    this.avatar,
    this.isVerified,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserModelToJson(this);
}

@JsonSerializable()
class AuthResponse {
  final String token;
  final UserModel user;
  final bool? isProfileComplete;

  AuthResponse({
    required this.token,
    required this.user,
    this.isProfileComplete,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}

@JsonSerializable()
class SendCodeRequest {
  final String phone;

  SendCodeRequest({required this.phone});

  factory SendCodeRequest.fromJson(Map<String, dynamic> json) =>
      _$SendCodeRequestFromJson(json);
  Map<String, dynamic> toJson() => _$SendCodeRequestToJson(this);
}

@JsonSerializable()
class VerifyCodeRequest {
  final String phone;
  final String code;

  VerifyCodeRequest({required this.phone, required this.code});

  factory VerifyCodeRequest.fromJson(Map<String, dynamic> json) =>
      _$VerifyCodeRequestFromJson(json);
  Map<String, dynamic> toJson() => _$VerifyCodeRequestToJson(this);
}

@JsonSerializable()
class CompleteProfileRequest {
  final String firstName;
  final String surname;
  final String? email;
  final String gender;
  final String region;

  CompleteProfileRequest({
    required this.firstName,
    required this.surname,
    this.email,
    required this.gender,
    required this.region,
  });

  factory CompleteProfileRequest.fromJson(Map<String, dynamic> json) =>
      _$CompleteProfileRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CompleteProfileRequestToJson(this);
}
