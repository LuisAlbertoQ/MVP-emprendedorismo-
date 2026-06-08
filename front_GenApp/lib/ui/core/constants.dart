class AppStrings {
  static const String appName = 'GeneApp Andina';
  static const String login = 'Iniciar Sesión';
  static const String register = 'Registrarse';
  static const String telefono = 'Teléfono';
  static const String nombre = 'Nombre';
  static const String password = 'Contraseña';
  static const String guardar = 'Guardar';
  static const String cancelar = 'Cancelar';
  static const String eliminar = 'Eliminar';
  static const String editar = 'Editar';
  static const String criar = 'Crear Animal';
  static const String planGratuito = 'Gratuito';
  static const String planBasico = 'Básico';
  static const String planCriador = 'Criador';
  static const String noHayAnimales = 'No hay animales registrados';
  static const String cargando = 'Cargando...';
  static const String errorRed = 'Error de conexión';
}

class AppRoutes {
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String home = '/';
  static const String animales = '/animales';
  static const String animalesCrear = '/animales/crear';
  static String animalDetalle(String uid) => '/animales/$uid';
  static String animalEditar(String uid) => '/animales/$uid/editar';
  static String animalArbol(String uid) => '/animales/$uid/arbol';
  static const String perfil = '/perfil';
  static const String reportes = '/reportes';
}
