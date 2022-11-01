class Book{
  final String name;
  final String path;
  final int progress;
  final int length;
  final DateTime accessed;
  const Book({
    required this.name,
    required this.path,
    required this.progress,
    required this.length,
    required this.accessed
  });
}