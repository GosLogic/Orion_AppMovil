/// Contrato para inyectar credenciales multi-tenant en el cliente HTTP.
abstract class AuthTokenProvider {
  Future<String?> getJwt();

  Future<String?> getTenantId();

  Future<bool> hasValidSession();
}
