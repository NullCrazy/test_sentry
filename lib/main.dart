import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:sentry_dio/sentry_dio.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://273b300f85304bce91a6383bf0f4dc8a@o4505079180886016.ingest.sentry.io/4505079185276928';
      options.tracesSampleRate = 1.0;
      options.debug = true;
      options.sendDefaultPii = true;
      options.maxRequestBodySize = MaxRequestBodySize.small;
      options.maxResponseBodySize = MaxResponseBodySize.small;
    },
    appRunner: () => runApp(DefaultAssetBundle(
      bundle: SentryAssetBundle(),
      child: const MyApp(),
    )),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      navigatorObservers: [SentryNavigatorObserver()],
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void test() {}

  void _incrementCounter() async {
    setState(() {
      _counter++;
    });
    final dio = Dio();
    dio.addSentry();

    final transaction = Sentry.startTransaction(
      'dio-web-request',
      'request',
      bindToScope: true,
    );

    try {
      final response =
          await dio.get<Map<String, Object?>>('https://api.github.com/search/users?q=aa');
      print(response.toString());
      transaction.status = SpanStatus.fromHttpStatusCode(response.statusCode ?? -1);
    } catch (exception) {
      transaction.throwable = exception;
      transaction.status = const SpanStatus.internalError();
    } finally {
      await transaction.finish();
    }

    await Sentry.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
