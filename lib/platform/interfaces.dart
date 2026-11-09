/// Saves a text file for the player (browser download).
abstract class FileDownloader {
  void download(String filename, String content, {String mime});
}

/// Opens a link in a new tab, only ever called from a tap.
abstract class LinkOpener {
  void open(String url);
}

class FakeFileDownloader implements FileDownloader {
  final List<({String filename, String content, String mime})> downloads = [];

  @override
  void download(
    String filename,
    String content, {
    String mime = 'application/json',
  }) {
    downloads.add((filename: filename, content: content, mime: mime));
  }
}

class FakeLinkOpener implements LinkOpener {
  final List<String> opened = [];

  @override
  void open(String url) => opened.add(url);
}
