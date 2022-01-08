import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'google_sign_in.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String appName = 'Fazendo leitura....';
  String packageName = 'Fazendo leitura....';
  String version = 'Fazendo leitura....';
  String buildNumber = 'Fazendo leitura....';

  @override
  void initState() {
    PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
      setState(() {
        appName = packageInfo.appName;
        packageName = packageInfo.packageName;
        version = packageInfo.version;
        buildNumber = packageInfo.buildNumber;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title,
            style: Theme.of(context).appBarTheme.titleTextStyle),
        actions: [
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sobre'),
                  content: Card(
                    elevation: 1.0,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            text: '$appName\n',
                            style: Theme.of(context).textTheme.headline4,
                          ),
                        ),
                        RichText(
                          text: TextSpan(
                            text: 'Versão: \n',
                            style: Theme.of(context).textTheme.headline4,
                            children: <TextSpan>[
                              TextSpan(
                                  text: '$version\n\n',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              TextSpan(text: 'Build: $buildNumber'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      child: Text('OK',
                          style: Theme.of(context).textTheme.headline4),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                final provider =
                    Provider.of<GoogleSignInProvider>(context, listen: false);
                provider.googleLogin();
              },
              child: const Text('Usar Gmail'),
            ),
          ],
        ),
      ),
    );
  }
}
