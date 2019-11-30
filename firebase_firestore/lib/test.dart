// File created by
// Lung Razvan <long1eu>
// on 27/11/2019

import 'dart:io';

import 'package:firebase_common/firebase_common.dart';
import 'package:firebase_firestore/firebase_firestore.dart';
import 'package:firebase_firestore/src/firebase/firestore/auth/credentials_provider.dart';
import 'package:firebase_firestore/src/firebase/firestore/core/database_info.dart';
import 'package:firebase_firestore/src/firebase/firestore/core/firestore_client.dart';
import 'package:firebase_firestore/src/firebase/firestore/model/database_id.dart';
import 'package:firebase_firestore/src/firebase/firestore/util/async_queue.dart';
import 'package:firebase_internal/firebase_internal.dart';
import 'package:hive/hive.dart';
import 'package:dart_sqlite/dart_sqlite.dart' as sql;
import 'src/firebase/firestore/auth/empty_credentials_provider.dart';

Future<void> main() async {
  final Dependencies dependencies = Dependencies();
  final FirebaseOptions options = FirebaseOptions(
    apiKey: 'AIzaSyApD5DJ2oSzosgy-pT0HPfqtCNh7st9dwM',
    applicationId: '1:233259864964:android:ef48439a0cc0263d',
    projectId: 'flutter-sdk',
  );
  final FirebaseApp app = FirebaseApp.withOptions(options, dependencies);

  final String projectId = app.options.projectId;
  if (projectId == null) {
    throw ArgumentError('FirebaseOptions.getProjectId() cannot be null');
  }
  final DatabaseId databaseId = DatabaseId.forDatabase(projectId, DatabaseId.defaultDatabaseId);

  final AsyncQueue queue = AsyncQueue();

  final CredentialsProvider provider = EmptyCredentialsProvider();

  // Firestore uses a different database for each app name. Note that we don't use
  // app.getPersistenceKey() here because it includes the application ID which is related to the
  // project ID. We already include the project ID when resolving the database, so there is no
  // need to include it in the persistence key.
  final String persistenceKey = app.name;

  final FirebaseFirestoreSettings settings = FirebaseFirestoreSettings();
  final FirestoreClient client = await FirestoreClient.initialize(
    DatabaseInfo(
      databaseId,
      persistenceKey,
      settings.host,
      sslEnabled: settings.sslEnabled,
    ),
    provider,
    queue,
    DatabaseMock.create,
    usePersistence: settings.persistenceEnabled,
  );

  final FirebaseFirestore firestore = FirebaseFirestore(databaseId, queue, app, client);

  final DocumentSnapshot data = await firestore.document('messages/00J0fQA7cSSQ5oYmfxL6').get();

  print(data.data);
}

class Dependencies extends PlatformDependencies {
  Dependencies() : headersBuilder = null;

  @override
  final HeaderBuilder headersBuilder;

  @override
  InternalTokenProvider get authProvider => null;

  @override
  AuthUrlPresenter get authUrlPresenter => null;

  @override
  bool get isBackground => false;

  @override
  Future<bool> get isNetworkConnected => Future<bool>.value(true);

  @override
  String get locale => 'en';

  @override
  Stream<bool> get isBackgroundChanged => Stream<bool>.fromIterable(<bool>[true]);

  @override
  Box<dynamic> get box => null;
}


class DatabaseMock extends Database {
  DatabaseMock._(this.database, this.path);

  sql.Database database;
  File path;

  bool renamePath = true;

  static File pathForName(String name) {
    return File('${Directory.current.path}/build/test/$name');
  }

  static Future<DatabaseMock> create(String name,
      {int version,
        OnConfigure onConfigure,
        OnCreate onCreate,
        OnVersionChange onUpgrade,
        OnVersionChange onDowngrade,
        OnOpen onOpen}) async {
    version ??= 1;

    final File path = pathForName(name);
    final bool callOnCreate = !path.existsSync();
    path.createSync(recursive: true);

    final sql.Database database = sql.Database(path.path);
    final DatabaseMock mock = DatabaseMock._(database, path);

    await onConfigure?.call(mock);
    if (callOnCreate) {
      await onCreate?.call(mock, version);
      await database.execute('PRAGMA user_version = $version;');
    } else {
      final List<sql.Row> row = await database.query('PRAGMA user_version;').toList();
      final int currentVersion = row.first.toMap().values.first;

      if (currentVersion < version) {
        await onUpgrade?.call(mock, currentVersion, version);
        await database.execute('PRAGMA user_version = $version;');
      }

      if (currentVersion > version) {
        await database.execute('PRAGMA user_version = $version;');
        await onDowngrade?.call(mock, currentVersion, version);
      }
    }

    await onOpen?.call(mock);
    return mock;
  }

  @override
  Future<int> delete(String statement, [List<dynamic> arguments]) {
    return database.execute(statement, arguments ?? <dynamic>[]);
  }

  @override
  Future<void> execute(String statement, [List<dynamic> arguments]) async {
    await database.execute(statement, arguments ?? <dynamic>[]);
  }

  @override
  Future<List<Map<String, dynamic>>> query(String statement, [List<void> arguments]) async {
    return database //
        .query(statement, arguments ?? <dynamic>[])
        .toList()
        .then((List<sql.Row> rows) => rows.map((sql.Row row) => row.toMap()).toList());
  }

  @override
  void close() {
    database.close();
    if (renamePath) {
      path.renameSync('${path.path}_');
    }
  }
}