class ReadingSlide {
  final String title;
  final String content;
  // final List<SlideContent> content; // This will contain the order that text and images need to appear

  ReadingSlide({required this.title, required this.content});
}

// abstract class SlideContent {}
//
// class TextContent extends SlideContent {
//   final String text;
//   TextContent(this.text);
// }
//
// class ImageContent extends SlideContent {
//   final String imagePath;
//   final String? altText;
//   ImageContent(this.imagePath, {this.altText});
// }