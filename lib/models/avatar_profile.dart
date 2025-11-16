import 'package:flutter/material.dart';

class AvatarProfile {
  AvatarProfile({
    required this.hairType,
    required this.hairColor,
    required this.faceType,
    required this.expression,
    required this.shirtType,
    required this.shirtColor,
    required this.shoesType,
    required this.shoesColor,
  });

  final String hairType;
  final String hairColor;
  final String faceType;
  final String expression;
  final String shirtType;
  final String shirtColor;
  final String shoesType;
  final String shoesColor;

  static AvatarProfile defaults() => AvatarProfile(
        hairType: 'short',
        hairColor: '#FFD1DC',
        faceType: 'round',
        expression: 'smile',
        shirtType: 'basic',
        shirtColor: '#A4E4AF',
        shoesType: 'simple',
        shoesColor: '#D8CFFF',
      );

  AvatarProfile copyWith({
    String? hairType,
    String? hairColor,
    String? faceType,
    String? expression,
    String? shirtType,
    String? shirtColor,
    String? shoesType,
    String? shoesColor,
  }) {
    return AvatarProfile(
      hairType: hairType ?? this.hairType,
      hairColor: hairColor ?? this.hairColor,
      faceType: faceType ?? this.faceType,
      expression: expression ?? this.expression,
      shirtType: shirtType ?? this.shirtType,
      shirtColor: shirtColor ?? this.shirtColor,
      shoesType: shoesType ?? this.shoesType,
      shoesColor: shoesColor ?? this.shoesColor,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hairType': hairType,
      'hairColor': hairColor,
      'faceType': faceType,
      'expression': expression,
      'shirtType': shirtType,
      'shirtColor': shirtColor,
      'shoesType': shoesType,
      'shoesColor': shoesColor,
    };
  }

  factory AvatarProfile.fromJson(Map<String, dynamic> json) {
    return AvatarProfile(
      hairType: json['hairType'] as String? ?? 'short',
      hairColor: json['hairColor'] as String? ?? '#FFD1DC',
      faceType: json['faceType'] as String? ?? 'round',
      expression: json['expression'] as String? ?? 'smile',
      shirtType: json['shirtType'] as String? ?? 'basic',
      shirtColor: json['shirtColor'] as String? ?? '#A4E4AF',
      shoesType: json['shoesType'] as String? ?? 'simple',
      shoesColor: json['shoesColor'] as String? ?? '#D8CFFF',
    );
  }

  Color get hairColorValue => colorFromHex(hairColor);
  Color get shirtColorValue => colorFromHex(shirtColor);
  Color get shoesColorValue => colorFromHex(shoesColor);

  static Color colorFromHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  static String colorToHex(Color color) =>
      '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
}
