import "package:flutter/material.dart";

class MaterialTheme {
  final TextTheme textTheme;

  const MaterialTheme(this.textTheme);

  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff365e9d),
      surfaceTint: Color(0xff365e9d),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff769cdf),
      onPrimaryContainer: Color(0xff00326a),
      secondary: Color(0xff515f79),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xffd2e0ff),
      onSecondaryContainer: Color(0xff55637d),
      tertiary: Color(0xff0a666a),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff317f83),
      onTertiaryContainer: Color(0xfff3ffff),
      error: Color(0xffba1a1a),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffffdad6),
      onErrorContainer: Color(0xff93000a),
      surface: Color(0xfff9f9ff),
      onSurface: Color(0xff1a1c20),
      onSurfaceVariant: Color(0xff434750),
      outline: Color(0xff737781),
      outlineVariant: Color(0xffc3c6d2),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2f3035),
      inversePrimary: Color(0xffaac7ff),
      primaryFixed: Color(0xffd6e3ff),
      onPrimaryFixed: Color(0xff001b3e),
      primaryFixedDim: Color(0xffaac7ff),
      onPrimaryFixedVariant: Color(0xff194683),
      secondaryFixed: Color(0xffd6e3ff),
      onSecondaryFixed: Color(0xff0d1c32),
      secondaryFixedDim: Color(0xffb9c7e5),
      onSecondaryFixedVariant: Color(0xff3a4760),
      tertiaryFixed: Color(0xffa4eff3),
      onTertiaryFixed: Color(0xff002021),
      tertiaryFixedDim: Color(0xff89d3d7),
      onTertiaryFixedVariant: Color(0xff004f52),
      surfaceDim: Color(0xffdad9df),
      surfaceBright: Color(0xfff9f9ff),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff3f3f9),
      surfaceContainer: Color(0xffeeedf3),
      surfaceContainerHigh: Color(0xffe8e7ed),
      surfaceContainerHighest: Color(0xffe2e2e8),
    );
  }

  ThemeData light() {
    return theme(lightScheme());
  }

  static ColorScheme lightMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff00356f),
      surfaceTint: Color(0xff365e9d),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff466dad),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff29364f),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff606d88),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff003d40),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff28787c),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff740006),
      onError: Color(0xffffffff),
      errorContainer: Color(0xffcf2c27),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfff9f9ff),
      onSurface: Color(0xff0f1115),
      onSurfaceVariant: Color(0xff32363f),
      outline: Color(0xff4f525c),
      outlineVariant: Color(0xff696d77),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2f3035),
      inversePrimary: Color(0xffaac7ff),
      primaryFixed: Color(0xff466dad),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff2b5493),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff606d88),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff48556f),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff28787c),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff005f62),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffc6c6cc),
      surfaceBright: Color(0xfff9f9ff),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff3f3f9),
      surfaceContainer: Color(0xffe8e7ed),
      surfaceContainerHigh: Color(0xffdcdce2),
      surfaceContainerHighest: Color(0xffd1d1d7),
    );
  }

  ThemeData lightMediumContrast() {
    return theme(lightMediumContrastScheme());
  }

  static ColorScheme lightHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xff002b5d),
      surfaceTint: Color(0xff365e9d),
      onPrimary: Color(0xffffffff),
      primaryContainer: Color(0xff1c4986),
      onPrimaryContainer: Color(0xffffffff),
      secondary: Color(0xff1f2c44),
      onSecondary: Color(0xffffffff),
      secondaryContainer: Color(0xff3c4963),
      onSecondaryContainer: Color(0xffffffff),
      tertiary: Color(0xff003234),
      onTertiary: Color(0xffffffff),
      tertiaryContainer: Color(0xff005255),
      onTertiaryContainer: Color(0xffffffff),
      error: Color(0xff600004),
      onError: Color(0xffffffff),
      errorContainer: Color(0xff98000a),
      onErrorContainer: Color(0xffffffff),
      surface: Color(0xfff9f9ff),
      onSurface: Color(0xff000000),
      onSurfaceVariant: Color(0xff000000),
      outline: Color(0xff282c35),
      outlineVariant: Color(0xff454952),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xff2f3035),
      inversePrimary: Color(0xffaac7ff),
      primaryFixed: Color(0xff1c4986),
      onPrimaryFixed: Color(0xffffffff),
      primaryFixedDim: Color(0xff003269),
      onPrimaryFixedVariant: Color(0xffffffff),
      secondaryFixed: Color(0xff3c4963),
      onSecondaryFixed: Color(0xffffffff),
      secondaryFixedDim: Color(0xff25334b),
      onSecondaryFixedVariant: Color(0xffffffff),
      tertiaryFixed: Color(0xff005255),
      onTertiaryFixed: Color(0xffffffff),
      tertiaryFixedDim: Color(0xff00393c),
      onTertiaryFixedVariant: Color(0xffffffff),
      surfaceDim: Color(0xffb8b8be),
      surfaceBright: Color(0xfff9f9ff),
      surfaceContainerLowest: Color(0xffffffff),
      surfaceContainerLow: Color(0xfff1f0f6),
      surfaceContainer: Color(0xffe2e2e8),
      surfaceContainerHigh: Color(0xffd4d4da),
      surfaceContainerHighest: Color(0xffc6c6cc),
    );
  }

  ThemeData lightHighContrast() {
    return theme(lightHighContrastScheme());
  }

  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffaac7ff),
      surfaceTint: Color(0xffaac7ff),
      onPrimary: Color(0xff002f64),
      primaryContainer: Color(0xff769cdf),
      onPrimaryContainer: Color(0xff00326a),
      secondary: Color(0xffb9c7e5),
      onSecondary: Color(0xff233148),
      secondaryContainer: Color(0xff3c4962),
      onSecondaryContainer: Color(0xffabb9d6),
      tertiary: Color(0xff89d3d7),
      onTertiary: Color(0xff003739),
      tertiaryContainer: Color(0xff519ca0),
      onTertiaryContainer: Color(0xff002c2e),
      error: Color(0xffffb4ab),
      onError: Color(0xff690005),
      errorContainer: Color(0xff93000a),
      onErrorContainer: Color(0xffffdad6),
      surface: Color(0xff121317),
      onSurface: Color(0xffe2e2e8),
      onSurfaceVariant: Color(0xffc3c6d2),
      outline: Color(0xff8d909b),
      outlineVariant: Color(0xff434750),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe2e2e8),
      inversePrimary: Color(0xff365e9d),
      primaryFixed: Color(0xffd6e3ff),
      onPrimaryFixed: Color(0xff001b3e),
      primaryFixedDim: Color(0xffaac7ff),
      onPrimaryFixedVariant: Color(0xff194683),
      secondaryFixed: Color(0xffd6e3ff),
      onSecondaryFixed: Color(0xff0d1c32),
      secondaryFixedDim: Color(0xffb9c7e5),
      onSecondaryFixedVariant: Color(0xff3a4760),
      tertiaryFixed: Color(0xffa4eff3),
      onTertiaryFixed: Color(0xff002021),
      tertiaryFixedDim: Color(0xff89d3d7),
      onTertiaryFixedVariant: Color(0xff004f52),
      surfaceDim: Color(0xff121317),
      surfaceBright: Color(0xff38393e),
      surfaceContainerLowest: Color(0xff0c0e12),
      surfaceContainerLow: Color(0xff1a1c20),
      surfaceContainer: Color(0xff1e2024),
      surfaceContainerHigh: Color(0xff282a2e),
      surfaceContainerHighest: Color(0xff333539),
    );
  }

  ThemeData dark() {
    return theme(darkScheme());
  }

  static ColorScheme darkMediumContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffcdddff),
      surfaceTint: Color(0xffaac7ff),
      onPrimary: Color(0xff002551),
      primaryContainer: Color(0xff769cdf),
      onPrimaryContainer: Color(0xff000c22),
      secondary: Color(0xffcfddfc),
      onSecondary: Color(0xff18263d),
      secondaryContainer: Color(0xff8391ad),
      onSecondaryContainer: Color(0xff000000),
      tertiary: Color(0xff9ee9ed),
      onTertiary: Color(0xff002b2d),
      tertiaryContainer: Color(0xff519ca0),
      onTertiaryContainer: Color(0xff000000),
      error: Color(0xffffd2cc),
      onError: Color(0xff540003),
      errorContainer: Color(0xffff5449),
      onErrorContainer: Color(0xff000000),
      surface: Color(0xff121317),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffd9dce8),
      outline: Color(0xffaeb2bd),
      outlineVariant: Color(0xff8d909b),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe2e2e8),
      inversePrimary: Color(0xff1a4785),
      primaryFixed: Color(0xffd6e3ff),
      onPrimaryFixed: Color(0xff00112b),
      primaryFixedDim: Color(0xffaac7ff),
      onPrimaryFixedVariant: Color(0xff00356f),
      secondaryFixed: Color(0xffd6e3ff),
      onSecondaryFixed: Color(0xff031127),
      secondaryFixedDim: Color(0xffb9c7e5),
      onSecondaryFixedVariant: Color(0xff29364f),
      tertiaryFixed: Color(0xffa4eff3),
      onTertiaryFixed: Color(0xff001415),
      tertiaryFixedDim: Color(0xff89d3d7),
      onTertiaryFixedVariant: Color(0xff003d40),
      surfaceDim: Color(0xff121317),
      surfaceBright: Color(0xff434449),
      surfaceContainerLowest: Color(0xff06070b),
      surfaceContainerLow: Color(0xff1c1e22),
      surfaceContainer: Color(0xff26282c),
      surfaceContainerHigh: Color(0xff313237),
      surfaceContainerHighest: Color(0xff3c3d42),
    );
  }

  ThemeData darkMediumContrast() {
    return theme(darkMediumContrastScheme());
  }

  static ColorScheme darkHighContrastScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xffebf0ff),
      surfaceTint: Color(0xffaac7ff),
      onPrimary: Color(0xff000000),
      primaryContainer: Color(0xffa4c3ff),
      onPrimaryContainer: Color(0xff000b20),
      secondary: Color(0xffebf0ff),
      onSecondary: Color(0xff000000),
      secondaryContainer: Color(0xffb5c3e1),
      onSecondaryContainer: Color(0xff000b20),
      tertiary: Color(0xffbafbff),
      onTertiary: Color(0xff000000),
      tertiaryContainer: Color(0xff85cfd3),
      onTertiaryContainer: Color(0xff000e0f),
      error: Color(0xffffece9),
      onError: Color(0xff000000),
      errorContainer: Color(0xffffaea4),
      onErrorContainer: Color(0xff220001),
      surface: Color(0xff121317),
      onSurface: Color(0xffffffff),
      onSurfaceVariant: Color(0xffffffff),
      outline: Color(0xffedf0fb),
      outlineVariant: Color(0xffbfc2ce),
      shadow: Color(0xff000000),
      scrim: Color(0xff000000),
      inverseSurface: Color(0xffe2e2e8),
      inversePrimary: Color(0xff1a4785),
      primaryFixed: Color(0xffd6e3ff),
      onPrimaryFixed: Color(0xff000000),
      primaryFixedDim: Color(0xffaac7ff),
      onPrimaryFixedVariant: Color(0xff00112b),
      secondaryFixed: Color(0xffd6e3ff),
      onSecondaryFixed: Color(0xff000000),
      secondaryFixedDim: Color(0xffb9c7e5),
      onSecondaryFixedVariant: Color(0xff031127),
      tertiaryFixed: Color(0xffa4eff3),
      onTertiaryFixed: Color(0xff000000),
      tertiaryFixedDim: Color(0xff89d3d7),
      onTertiaryFixedVariant: Color(0xff001415),
      surfaceDim: Color(0xff121317),
      surfaceBright: Color(0xff4f5055),
      surfaceContainerLowest: Color(0xff000000),
      surfaceContainerLow: Color(0xff1e2024),
      surfaceContainer: Color(0xff2f3035),
      surfaceContainerHigh: Color(0xff3a3b40),
      surfaceContainerHighest: Color(0xff45474b),
    );
  }

  ThemeData darkHighContrast() {
    return theme(darkHighContrastScheme());
  }


  ThemeData theme(ColorScheme colorScheme) => ThemeData(
     useMaterial3: true,
     brightness: colorScheme.brightness,
     colorScheme: colorScheme,
     textTheme: textTheme.apply(
       bodyColor: colorScheme.onSurface,
       displayColor: colorScheme.onSurface,
     ),
     scaffoldBackgroundColor: colorScheme.surface,
     canvasColor: colorScheme.surface,
  );


  List<ExtendedColor> get extendedColors => [
  ];
}

class ExtendedColor {
  final Color seed, value;
  final ColorFamily light;
  final ColorFamily lightHighContrast;
  final ColorFamily lightMediumContrast;
  final ColorFamily dark;
  final ColorFamily darkHighContrast;
  final ColorFamily darkMediumContrast;

  const ExtendedColor({
    required this.seed,
    required this.value,
    required this.light,
    required this.lightHighContrast,
    required this.lightMediumContrast,
    required this.dark,
    required this.darkHighContrast,
    required this.darkMediumContrast,
  });
}

class ColorFamily {
  const ColorFamily({
    required this.color,
    required this.onColor,
    required this.colorContainer,
    required this.onColorContainer,
  });

  final Color color;
  final Color onColor;
  final Color colorContainer;
  final Color onColorContainer;
}
