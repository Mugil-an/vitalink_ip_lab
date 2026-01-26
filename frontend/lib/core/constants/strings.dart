class AppStrings {
	AppStrings._();

	/// Base URL for the backend API.
	/// Note: Use http for local dev to avoid TLS/host issues in Flutter web.
	static const String apiBaseUrl = 'http://localhost:3000';

	/// Auth endpoints.
	static const String loginPath = '/api/auth/login';

	/// Doctor endpoints.
	static const String doctorPatientsPath = '/api/doctors/patients';

	/// Secure storage keys.
	static const String tokenKey = 'auth_token';
	static const String userKey = 'auth_user';
}
