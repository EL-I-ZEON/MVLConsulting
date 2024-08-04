import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(MVLConsultingApp());
}

class MVLConsultingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MVL Consulting',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late InAppWebViewController webViewController;
  bool isLoading = true;
  bool isOffline = false;
  String offlineHtmlContent = '';

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadOfflineHtmlContent();
  }

  Future<void> _checkConnectivity() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        isOffline = true;
      });
    } else {
      setState(() {
        isOffline = false;
      });
    }
  }

  Future<void> _loadOfflineHtmlContent() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      offlineHtmlContent = prefs.getString('offlineHtmlContent') ?? '';
    });
  }

  Future<void> _saveOfflineHtmlContent(String htmlContent) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('offlineHtmlContent', htmlContent);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (await webViewController.canGoBack()) {
          webViewController.goBack();
          return false;
        } else {
          return true;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('MVL Consulting'),
          actions: [
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () async {
                await _checkConnectivity();
                if (isOffline) {
                  if (offlineHtmlContent.isNotEmpty) {
                    webViewController.loadData(data: offlineHtmlContent);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                          "Žiadne internetové pripojenie a nie sú k dispozícii žiadne uložené údaje."),
                    ));
                  }
                } else {
                  webViewController.reload();
                }
              },
            ),
          ],
        ),
        body: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async {
                await _checkConnectivity();
                if (isOffline) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Žiadne internetové pripojenie."),
                  ));
                } else {
                  webViewController.reload();
                }
              },
              child: isOffline
                  ? Center(
                child: offlineHtmlContent.isNotEmpty
                    ? InAppWebView(
                  initialData: InAppWebViewInitialData(
                      data: offlineHtmlContent),
                  onWebViewCreated: (controller) {
                    webViewController = controller;
                  },
                )
                    : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Žiadne internetové pripojenie a nie sú k dispozícii žiadne uložené údaje.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
                  : InAppWebView(
                initialUrlRequest: URLRequest(
                    url: Uri.parse('https://www.mvlconsulting.sk/')),
                onWebViewCreated: (controller) {
                  webViewController = controller;
                },
                onLoadStart: (controller, url) {
                  setState(() {
                    isLoading = true;
                  });
                },
                onLoadStop: (controller, url) async {
                  setState(() {
                    isLoading = false;
                  });
                  String htmlContent =
                      await webViewController.evaluateJavascript(
                          source:
                          "document.documentElement.outerHTML") ??
                          "";
                  _saveOfflineHtmlContent(htmlContent);
                },
                onLoadError: (controller, url, code, message) {
                  setState(() {
                    isLoading = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text("Error loading page: $message"),
                  ));
                },
                shouldOverrideUrlLoading:
                    (controller, navigationAction) async {
                  var uri = navigationAction.request.url!;
                  if (uri.scheme == 'tel' ||
                      uri.scheme == 'mailto' ||
                      uri.scheme == 'sms') {
                    if (await canLaunch(uri.toString())) {
                      await launch(uri.toString());
                      return NavigationActionPolicy.CANCEL;
                    }
                  }
                  return NavigationActionPolicy.ALLOW;
                },
              ),
            ),
            if (isLoading)
              Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.white,  // Background color
          selectedItemColor: Colors.black,  // Selected item color
          unselectedItemColor: Colors.black,  // Unselected item color
          showSelectedLabels: false,  // Hide the selected item label
          showUnselectedLabels: false,  // Hide the unselected item label
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.phone),
              label: 'Mobil',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.info),
              label: 'O Nás',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.contact_mail),
              label: 'Email',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.navigation),
              label: 'Navigácia',
            ),
          ],
          onTap: (index) {
            switch (index) {
              case 0:
                final Uri phoneLaunchUri = Uri(
                  scheme: 'tel',
                  path: '+421908184948',
                );
                launch(phoneLaunchUri.toString());
                break;
              case 1:
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('O nás'),
                      content: SingleChildScrollView(
                        child: ListBody(
                          children: [
                            Text(
                                'MVL consulting je dôveryhodný obchodný partner poskytujúci poradenské služby v rôznych oblastiach, ako účtovníctvo, mzdy, daňové priznania, DPH, daň z príjmu, daň z motorových vozidiel, komunikácia so Sociálnou poisťovňou, so Zdravotnými poisťovňami, s daňovým úradom. '
                                    '\n\nKancelária: Skladná 1, Košice 040 01'
                                    '\nFakturačné údaje: MVL consulting s.r.o.'
                                    '\nMaurerova 756/13, 040 22 Košice - mestská časť Dargovských hrdinov'
                                    '\n\nIČO: 47462540'
                                    '\nDIČ: 2023949796'
                                    '\nIČ DPH: SK2023949796, podľa §4'),
                          ],
                        ),
                      ),
                      actions: <Widget>[
                        TextButton(
                          child: Text('Zavrieť'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    );
                  },
                );
                break;
              case 2:
                final Uri emailLaunchUri = Uri(
                  scheme: 'mailto',
                  path: 'lsoltys@mvlconsulting.sk',
                );
                launch(emailLaunchUri.toString());
                break;
              case 3:
                final Uri navigationUri = Uri.parse(
                    'https://www.google.com/maps/dir/?api=1&destination=Skladná+1,+Košice+Slovakia');
                launch(navigationUri.toString());
                break;
            }
          },
        ),
      ),
    );
  }
}