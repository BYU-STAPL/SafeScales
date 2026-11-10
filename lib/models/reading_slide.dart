import 'question.dart';

class ReadingSlide {
  final String title;
  final String content;
  final Question? checkpointQuestion;

  ReadingSlide({
    required this.title,
    required this.content,
    this.checkpointQuestion,
  });

  factory ReadingSlide.checkpoint({
    required String title,
    required Question question,
  }) {
    return ReadingSlide(
      title: title,
      content: '',
      checkpointQuestion: question,
    );
  }

  bool get isCheckpoint => checkpointQuestion != null;
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
