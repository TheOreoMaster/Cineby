import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'Cineby',
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        brightness: Brightness.dark,
        primaryColor: CupertinoColors.systemOrange,
      ),
      home: WebViewPage(),
    );
  }
}

class WebViewPage extends StatefulWidget {
  const WebViewPage({super.key});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  InAppWebViewController? webViewController;
  PullToRefreshController? pullToRefreshController;
  double progress = 0;

  // Brave-like Ad-blocking and Privacy Rules
  final List<ContentBlocker> contentBlockers = [
    // 1. Block common ad and tracking domains
    ContentBlocker(
      trigger: ContentBlockerTrigger(
        urlFilter: ".*(google-analytics|googletagmanager|doubleclick|adservice|facebook|app-measurement|adnxs|pubmatic|casalemedia|rubiconproject|openx|yieldmo|moatads|tpmn|smartadserver|adform|gumgum|scorecardresearch|advertising|popads|popcash|propellerads|exoclick|adsterra|mgid|revcontent|taboola|outbrain)\.(com|net|org|biz|info|tv).*",
      ),
      action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK),
    ),
    // 2. Block specific script paths used for popups and ads
    ContentBlocker(
      trigger: ContentBlockerTrigger(
        urlFilter: ".*\\/(ads|advertising|popads|popcash|analytics|track|pixel|telemetry|beacon|adframe|adloader|ad-management|popunder)\\.js.*",
      ),
      action: ContentBlockerAction(type: ContentBlockerActionType.BLOCK),
    ),
    // 3. Hide ad-related UI elements via CSS (Cosmetic Filtering)
    ContentBlocker(
      trigger: ContentBlockerTrigger(
        urlFilter: ".*",
      ),
      action: ContentBlockerAction(
        type: ContentBlockerActionType.CSS_DISPLAY_NONE,
        selector: ".ads, .ads-container, #ad-banner, .banner-ads, [id^='ad-'], [class^='ad-'], .popup-overlay, .sticky-ad, .ad-unit, .premium-ad, [data-ad-id], .mgid-wrapper, .trc_related_container",
      ),
    ),
  ];

  @override
  void initState() {
    super.initState();
    pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(
        color: CupertinoColors.systemOrange,
      ),
      onRefresh: () async {
        webViewController?.reload();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        child: Column(
          children: [
            // Loading Progress Bar
            if (progress < 1.0)
              SizedBox(
                height: 2,
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: CupertinoColors.black,
                  valueColor: const AlwaysStoppedAnimation<Color>(CupertinoColors.systemOrange),
                ),
              ),
            Expanded(
              child: InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri("https://cineby.sc")),
                initialSettings: InAppWebViewSettings(
                  allowsInlineMediaPlayback: true,
                  javaScriptEnabled: true,
                  contentBlockers: contentBlockers,
                  mediaPlaybackRequiresUserGesture: false,
                  userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1",
                  allowsBackForwardNavigationGestures: true,
                  verticalScrollBarEnabled: false,
                  horizontalScrollBarEnabled: false,
                  useOnDownloadStart: true,
                  useShouldOverrideUrlLoading: true,
                  allowsPictureInPictureMediaPlayback: true,
                ),
                pullToRefreshController: pullToRefreshController,
                onWebViewCreated: (controller) {
                  webViewController = controller;
                },
                onLoadStart: (controller, url) {
                  setState(() => progress = 0);
                },
                onLoadStop: (controller, url) {
                  pullToRefreshController?.endRefreshing();
                  setState(() => progress = 1.0);
                },
                onProgressChanged: (controller, p) {
                  if (p == 100) pullToRefreshController?.endRefreshing();
                  setState(() => progress = p / 100);
                },
                onCreateWindow: (controller, createWindowAction) async {
                  // Block any attempt to open a new window/tab (prevents popups)
                  return false;
                },
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  var uri = navigationAction.request.url;
                  // Restrict navigation to valid web protocols
                  if (!["http", "https"].contains(uri?.scheme)) {
                    return NavigationActionPolicy.CANCEL;
                  }
                  return NavigationActionPolicy.ALLOW;
                },
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      height: 50,
      decoration: const BoxDecoration(
        color: CupertinoColors.black,
        border: Border(top: BorderSide(color: CupertinoColors.systemGrey, width: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Icon(CupertinoIcons.back, color: CupertinoColors.white),
            onPressed: () => webViewController?.goBack(),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Icon(CupertinoIcons.forward, color: CupertinoColors.white),
            onPressed: () => webViewController?.goForward(),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Icon(CupertinoIcons.refresh, color: CupertinoColors.white),
            onPressed: () => webViewController?.reload(),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Icon(CupertinoIcons.home, color: CupertinoColors.white),
            onPressed: () => webViewController?.loadUrl(
              urlRequest: URLRequest(url: WebUri("https://cineby.sc")),
            ),
          ),
        ],
      ),
    );
  }
}
