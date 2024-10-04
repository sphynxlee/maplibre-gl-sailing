import 'dart:ui_web' as ui;
import 'dart:html';

void initializeForWeb() {
  ui.platformViewRegistry.registerViewFactory('example', (_) => DivElement()..innerText = 'Hello, HTML!');
}