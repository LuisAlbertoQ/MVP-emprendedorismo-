import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:front_genapp/data/models/animal_model.dart';
import 'package:front_genapp/data/repositories/animal_repository.dart';
import 'package:front_genapp/ui/features/auth/providers/auth_provider.dart';

final animalRepositoryProvider = Provider<AnimalRepository>((ref) {
  return AnimalRepository(ref.read(apiServiceProvider));
});

final animalListProvider =
    StateNotifierProvider<AnimalListNotifier, AnimalListState>((ref) {
  return AnimalListNotifier(ref.read(animalRepositoryProvider));
});

class AnimalListState {
  final List<AnimalListModel> animales;
  final bool isLoading;
  final String? error;
  final int page;
  final bool hasMore;
  final String? filtroEspecie;
  final String? filtroSexo;
  final String search;

  const AnimalListState({
    this.animales = const [],
    this.isLoading = false,
    this.error,
    this.page = 1,
    this.hasMore = true,
    this.filtroEspecie,
    this.filtroSexo,
    this.search = '',
  });

  AnimalListState copyWith({
    List<AnimalListModel>? animales,
    bool? isLoading,
    String? error,
    int? page,
    bool? hasMore,
    String? filtroEspecie,
    String? filtroSexo,
    String? search,
  }) {
    return AnimalListState(
      animales: animales ?? this.animales,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      filtroEspecie: filtroEspecie ?? this.filtroEspecie,
      filtroSexo: filtroSexo ?? this.filtroSexo,
      search: search ?? this.search,
    );
  }
}

class AnimalListNotifier extends StateNotifier<AnimalListState> {
  final AnimalRepository _repo;

  AnimalListNotifier(this._repo) : super(const AnimalListState());

  Future<void> loadAnimales({bool refresh = false}) async {
    if (refresh) {
      state = AnimalListState(
        filtroEspecie: state.filtroEspecie,
        filtroSexo: state.filtroSexo,
        search: state.search,
      );
    }
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final items = await _repo.getAnimales(
        page: state.page,
        especie: state.filtroEspecie,
        sexo: state.filtroSexo,
        search: state.search,
      );
      state = state.copyWith(
        animales: refresh ? items : [...state.animales, ...items],
        isLoading: false,
        page: state.page + 1,
        hasMore: items.length >= 20,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, hasMore: false, error: e.toString());
    }
  }

  void setFiltros({String? especie, String? sexo}) {
    state = AnimalListState(
      filtroEspecie: especie,
      filtroSexo: sexo,
      search: state.search,
    );
    loadAnimales(refresh: true);
  }

  void setSearch(String query) {
    state = AnimalListState(
      filtroEspecie: state.filtroEspecie,
      filtroSexo: state.filtroSexo,
      search: query,
    );
    loadAnimales(refresh: true);
  }
}

final animalDetailProvider =
    FutureProvider.family<AnimalModel, String>((ref, uid) {
  return ref.read(animalRepositoryProvider).getAnimal(uid);
});

final animalArbolProvider =
    FutureProvider.family<ArbolNode, String>((ref, uid) {
  return ref.read(animalRepositoryProvider).getArbol(uid);
});

final resumenProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.read(animalRepositoryProvider).getResumen();
});
