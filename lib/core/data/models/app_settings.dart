import '../../constants/app_constants.dart';

/// App settings model for user preferences
class AppSettings {
  final bool darkMode;
  final double fontSize;
  final ScrollDirection scrollDirection;
  final bool autoCropMargins;
  final double brightness;

  AppSettings({
    this.darkMode = AppConstants.defaultDarkMode,
    this.fontSize = AppConstants.defaultFontSize,
    this.scrollDirection = AppConstants.defaultScrollDirection,
    this.autoCropMargins = AppConstants.defaultAutoCrop,
    this.brightness = AppConstants.defaultBrightness,
  });

  /// Default settings
  factory AppSettings.defaultSettings() {
    return AppSettings();
  }

  /// From JSON
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      darkMode: json['darkMode'] as bool? ?? AppConstants.defaultDarkMode,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? AppConstants.defaultFontSize,
      scrollDirection: json['scrollDirection'] == 'horizontal'
          ? ScrollDirection.horizontal
          : ScrollDirection.vertical,
      autoCropMargins: json['autoCropMargins'] as bool? ?? AppConstants.defaultAutoCrop,
      brightness: (json['brightness'] as num?)?.toDouble() ?? AppConstants.defaultBrightness,
    );
  }

  /// To JSON
  Map<String, dynamic> toJson() {
    return {
      'darkMode': darkMode,
      'fontSize': fontSize,
      'scrollDirection': scrollDirection == ScrollDirection.horizontal ? 'horizontal' : 'vertical',
      'autoCropMargins': autoCropMargins,
      'brightness': brightness,
    };
  }

  AppSettings copyWith({
    bool? darkMode,
    double? fontSize,
    ScrollDirection? scrollDirection,
    bool? autoCropMargins,
    double? brightness,
  }) {
    return AppSettings(
      darkMode: darkMode ?? this.darkMode,
      fontSize: fontSize ?? this.fontSize,
      scrollDirection: scrollDirection ?? this.scrollDirection,
      autoCropMargins: autoCropMargins ?? this.autoCropMargins,
      brightness: brightness ?? this.brightness,
    );
  }
}
