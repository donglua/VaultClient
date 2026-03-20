import 'dart:typed_data';
import 'package:webdav_client/webdav_client.dart' as webdav;

/// WebDAV 网络服务，封装 webdav_client 包，
/// 提供上传、下载、目录管理等高层异步方法。
class WebDAVService {
  late webdav.Client client;

  /// 使用凭证初始化 WebDAV 客户端。
  ///
  /// [url] WebDAV 服务器的根地址。
  /// [username] 认证用户名。
  /// [password] 认证密码或应用令牌。
  void init(String url, String username, String password) {
    client = webdav.newClient(
      url,
      user: username,
      password: password,
    );
  }

  /// 检测服务器连通性并验证凭证。
  /// 返回 `true` 表示服务器可达且凭证有效。
  Future<bool> ping() async {
    try {
      await client.ping();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 读取远程目录内容。
  /// 返回包含文件和子文件夹的 [webdav.File] 列表。
  Future<List<webdav.File>> readDir(String path) async {
    return await client.readDir(path);
  }

  /// 在远程服务器的 [path] 路径创建目录。
  /// 如果目录已存在则忽略错误。
  Future<void> mkCol(String path) async {
    try {
      await client.mkdir(path);
    } catch (e) {
      // 目录已存在则忽略
    }
  }

  /// 将本地文件上传到指定的远程路径。
  Future<void> uploadFile(String remotePath, String localFilePath) async {
    await client.writeFromFile(localFilePath, remotePath);
  }

  /// 将字节数组直接上传到远程 [remotePath]。
  Future<void> upload(String remotePath, List<int> bytes) async {
    await client.write(remotePath, Uint8List.fromList(bytes));
  }

  /// 将远程文件下载到本地设备存储。
  Future<void> downloadFile(String remotePath, String localFilePath) async {
    await client.read2File(remotePath, localFilePath);
  }

  /// 将远程文件直接读取到内存中。
  Future<List<int>> download(String remotePath) async {
    return await client.read(remotePath);
  }

  /// 删除远程服务器上 [remotePath] 位置的文件或目录。
  Future<void> delete(String remotePath) async {
    await client.removeAll(remotePath);
  }
}
