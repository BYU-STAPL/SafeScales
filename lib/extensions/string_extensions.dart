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

}