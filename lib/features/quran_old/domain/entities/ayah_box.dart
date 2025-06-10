class AyahBox {
  final int x, y, width, height;

  AyahBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory AyahBox.fromJson(Map<String, dynamic> shape) {
    return AyahBox(
      x: shape['x'],
      y: shape['y'],
      width: shape['width'],
      height: shape['height'],
    );
  }
}