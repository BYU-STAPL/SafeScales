extension StringExtension on String {
  String toTitleCase() {
    return split(' ').map((word) =>
    word.isEmpty ? word : word[0].toUpperCase() + word.substring(1).toLowerCase()
    ).join(' ');
  }

  // You can add more string extensions here
  String capitalize() {
    return isEmpty ? this : this[0].toUpperCase() + substring(1);
  }

  String lastChars(int n) => substring(length - n);

  /// Removes markdown image syntax and image URLs for table-of-contents display
  /// so image links are not shown in the TOC (pre/post quiz, review, reading).
  String stripImageLinksForToc() {
    String s = this;
    // Remove markdown images: ![alt](url)
    s = s.replaceAll(RegExp(r'!\[[^\]]*\]\s*\([^)]*\)'), ' ');
    // Remove standalone image URLs (common extensions)
    s = s.replaceAll(
      RegExp(
        r'https?:\/\/\S+\.(png|jpg|jpeg|gif|webp|svg)(\?[^\s]*)?',
        caseSensitive: false,
      ),
      ' ',
    );
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}