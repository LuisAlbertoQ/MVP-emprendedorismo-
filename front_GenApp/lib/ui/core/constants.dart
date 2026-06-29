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
  static const String gestion = '/gestion';
  static const String consanguinidad = '/gestion/consanguinidad';
  static const String fibraRanking = '/gestion/fibra-ranking';
  static const String gestionReproductivo = '/gestion/reproductivo';
  static const String gestionFinanciero = '/gestion/financiero';
  static const String empadres = '/gestion/empadres';
  static const String empadresCrear = '/gestion/empadres/crear';
  static const String partos = '/gestion/partos';
  static const String partosCrear = '/gestion/partos/crear';
  static const String costos = '/gestion/costos';
  static const String costosCrear = '/gestion/costos/crear';
  static const String ventasFibra = '/gestion/ventas-fibra';
  static const String ventasFibraCrear = '/gestion/ventas-fibra/crear';
}
