class ToolItem {
  const ToolItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.goldPrice,
    required this.description,
  });

  final String id;
  final String name;
  final String emoji;
  final int goldPrice;
  final String description;
}
