enum LinkType { video, document, news, unknown }

class LinkTypeDetector {
  static const _videoDomains = [
    'youtube.com',
    'youtu.be',
    'tiktok.com',
    'vimeo.com',
    'facebook.com/watch',
    'fb.watch',
    'instagram.com/reel',
    'instagram.com/p',
    'twitter.com/i/status',
    'x.com',
    'dailymotion.com',
    'twitch.tv',
  ];

  static const _documentDomains = [
    'docs.google.com',
    'drive.google.com',
    'notion.so',
    'confluence',
    'github.com',
    'stackoverflow.com',
    'medium.com',
  ];

  static const _documentExtensions = ['.pdf', '.doc', '.docx', '.ppt', '.pptx', '.xls', '.xlsx'];

  static LinkType detect(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return LinkType.unknown;

    final url = rawUrl.toLowerCase();

    // Kiểm tra video domain/pattern
    if (_videoDomains.any((d) => url.contains(d))) {
      return LinkType.video;
    }

    // Kiểm tra file extension
    if (_documentExtensions.any((ext) => url.contains(ext))) {
      return LinkType.document;
    }

    // Kiểm tra document domain
    if (_documentDomains.any((d) => url.contains(d))) {
      return LinkType.document;
    }

    return LinkType.news; // mặc định coi là tin tức/bài viết
  }
}
