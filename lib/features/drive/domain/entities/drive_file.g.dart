// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drive_file.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DriveFileImpl _$$DriveFileImplFromJson(Map<String, dynamic> json) =>
    _$DriveFileImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      size: (json['size'] as num).toInt(),
      createdTime: DateTime.parse(json['createdTime'] as String),
      thumbnailLink: json['thumbnailLink'] as String?,
      webViewLink: json['webViewLink'] as String?,
    );

Map<String, dynamic> _$$DriveFileImplToJson(_$DriveFileImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'size': instance.size,
      'createdTime': instance.createdTime.toIso8601String(),
      'thumbnailLink': instance.thumbnailLink,
      'webViewLink': instance.webViewLink,
    };
