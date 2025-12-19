// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
      id: (json['id'] as num).toInt(),
      phone: json['phone'] as String,
      email: json['email'] as String?,
      firstName: json['firstName'] as String?,
      surname: json['surname'] as String?,
      gender: json['gender'] as String?,
      region: json['region'] as String?,
      isVerified: json['isVerified'] as bool?,
    );

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
      'id': instance.id,
      'phone': instance.phone,
      'email': instance.email,
      'firstName': instance.firstName,
      'surname': instance.surname,
      'gender': instance.gender,
      'region': instance.region,
      'isVerified': instance.isVerified,
    };

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) => AuthResponse(
      token: json['token'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      isProfileComplete: json['isProfileComplete'] as bool?,
    );

Map<String, dynamic> _$AuthResponseToJson(AuthResponse instance) =>
    <String, dynamic>{
      'token': instance.token,
      'user': instance.user,
      'isProfileComplete': instance.isProfileComplete,
    };

SendCodeRequest _$SendCodeRequestFromJson(Map<String, dynamic> json) =>
    SendCodeRequest(
      phone: json['phone'] as String,
    );

Map<String, dynamic> _$SendCodeRequestToJson(SendCodeRequest instance) =>
    <String, dynamic>{
      'phone': instance.phone,
    };

VerifyCodeRequest _$VerifyCodeRequestFromJson(Map<String, dynamic> json) =>
    VerifyCodeRequest(
      phone: json['phone'] as String,
      code: json['code'] as String,
    );

Map<String, dynamic> _$VerifyCodeRequestToJson(VerifyCodeRequest instance) =>
    <String, dynamic>{
      'phone': instance.phone,
      'code': instance.code,
    };

CompleteProfileRequest _$CompleteProfileRequestFromJson(
        Map<String, dynamic> json) =>
    CompleteProfileRequest(
      firstName: json['firstName'] as String,
      surname: json['surname'] as String,
      email: json['email'] as String?,
      gender: json['gender'] as String,
      region: json['region'] as String,
    );

Map<String, dynamic> _$CompleteProfileRequestToJson(
        CompleteProfileRequest instance) =>
    <String, dynamic>{
      'firstName': instance.firstName,
      'surname': instance.surname,
      'email': instance.email,
      'gender': instance.gender,
      'region': instance.region,
    };
