import 'dart:ui_web' as ui_web;
import 'package:universal_html/html.dart' as html;

void registerVideoPlayerFactory(String viewType, String videoUrl) {
  try {
    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) {
        final videoElement = html.VideoElement()
          ..src = videoUrl
          ..autoplay = true
          ..loop = true
          ..muted = true
          ..controls = true
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'cover';
        return videoElement;
      },
    );
  } catch (e) {
    // Avoid crashing if re-registered
  }
}
