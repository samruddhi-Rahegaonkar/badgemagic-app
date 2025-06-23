class ScreenSize {
  final int width;
  final int height;
  final String name;

  const ScreenSize(
      {required this.width, required this.height, required this.name});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScreenSize &&
          runtimeType == other.runtimeType &&
          width == other.width &&
          height == other.height &&
          name == other.name;

  @override
  int get hashCode => width.hashCode ^ height.hashCode ^ name.hashCode;
}

const List<ScreenSize> supportedScreenSizes = [
  ScreenSize(width: 44, height: 11, name: "Small (44x11)"),
  ScreenSize(width: 64, height: 16, name: "Medium (64x16)"),
  ScreenSize(width: 128, height: 32, name: "Large (128x32)"),
];
