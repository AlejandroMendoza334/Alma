class AIException implements Exception {
  final String message;
  final String? code;

  AIException(this.message, {this.code});

  @override
  String toString() => message;
}

class NoApiKeyException extends AIException {
  NoApiKeyException()
      : super('No has configurado una API Key. Agrégala en los Ajustes para hablar con Alma.');
}

class InvalidApiKeyException extends AIException {
  InvalidApiKeyException()
      : super('La API Key ingresada no es válida o ha sido revocada. Por favor verifícala en Ajustes.');
}

class QuotaExceededException extends AIException {
  QuotaExceededException()
      : super('Has alcanzado el límite de cuota o saldo en tu cuenta del proveedor de IA.');
}

class NetworkException extends AIException {
  NetworkException()
      : super('No se pudo establecer conexión a internet. Revisa tu red y vuelve a intentarlo.');
}

class ServerException extends AIException {
  ServerException()
      : super('El servidor de la IA está experimentando problemas temporales. Intenta de nuevo en unos minutos.');
}