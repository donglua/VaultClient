import 'dart:typed_data';
import 'package:webdav_client/webdav_client.dart' as webdav;

/// A service to interact with a WebDAV server.
///
/// This class acts as a wrapper around the `webdav_client` package,
/// providing higher-level, asynchronous methods to upload, download,
/// ping, and manage directories on a remote WebDAV server (such as Nextcloud, NAS, or Jianguoyun).
class WebDAVService {
  late webdav.Client client;

  /// Initializes the WebDAV client with credentials.
  ///
  /// [url] The base URL of the WebDAV server.
  /// [username] The authenticating user.
  /// [password] The app password or token for the WebDAV server.
  void init(String url, String username, String password) {
    client = webdav.newClient(
      url,
      user: username,
      password: password,
    );
  }

  /// Pings the WebDAV server to check connectivity and verify credentials.
  /// Returns `true` if the server is reachable and credentials are valid.
  Future<bool> ping() async {
    try {
      await client.ping();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Reads the contents of a directory on the remote server.
  /// Returns a list of [webdav.File] representing files and sub-folders.
  Future<List<webdav.File>> readDir(String path) async {
    return await client.readDir(path);
  }

  /// Creates a directory (collection) on the remote server at [path].
  /// Ignores the error if the directory already exists.
  Future<void> mkCol(String path) async {
    try {
      await client.mkdir(path);
    } catch (e) {
      // Ignore error if directory already exists
    }
  }

  /// Uploads a local file to the specified remote path.
  Future<void> uploadFile(String remotePath, String localFilePath) async {
    await client.writeFromFile(localFilePath, remotePath);
  }

  /// Uploads a list of bytes directly into a file at [remotePath].
  Future<void> upload(String remotePath, List<int> bytes) async {
    await client.write(Uint8List.fromList(bytes), remotePath);
  }

  /// Downloads a remote file to the local device storage.
  Future<void> downloadFile(String remotePath, String localFilePath) async {
    await client.read2File(remotePath, localFilePath);
  }

  /// Reads a remote file directly into memory.
  Future<List<int>> download(String remotePath) async {
    return await client.read(remotePath);
  }

  /// Deletes a file or directory at [remotePath] on the remote server.
  Future<void> delete(String remotePath) async {
    await client.removeAll(remotePath);
  }
}
