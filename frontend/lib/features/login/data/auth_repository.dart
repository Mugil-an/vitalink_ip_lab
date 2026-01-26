import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/storage/secure_storage.dart';
import 'package:frontend/features/login/models/login_models.dart';

class AuthRepository {
  AuthRepository({required ApiClient apiClient, required SecureStorage secureStorage})
      : _apiClient = apiClient,
        _secureStorage = secureStorage;

  final ApiClient _apiClient;
  final SecureStorage _secureStorage;

  Future<LoginResponse> login(LoginRequest request) async {
    final body = await _apiClient.post(
      request.path,
      data: request.toJson(),
      authenticated: false,
    );

    final token = body['token'] as String?;
    final userJson = body['user'] as Map<String, dynamic>?;

    if (token == null || userJson == null) {
      throw ApiException('Malformed login response');
    }

    await _secureStorage.saveToken(token);
    await _secureStorage.saveUser(userJson);

    return LoginResponse(
      token: token,
      user: UserModel.fromJson(userJson),
    );
  }
}
