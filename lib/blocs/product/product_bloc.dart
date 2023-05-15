import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:tkfoodadmin/repositories/restaurant/restaurant_repository.dart';
import '/blocs/blocs.dart';
import '/models/models.dart';

part 'product_event.dart';
part 'product_state.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final RestaurantRepository _restaurantRepository;
  final CategoryBloc _categoryBloc;
  StreamSubscription? _categorySubscription;
  StreamSubscription? _restaurantSubscription;

  ProductBloc(
      {required CategoryBloc categoryBloc,
      required RestaurantRepository restaurantRepository})
      : _categoryBloc = categoryBloc,
        _restaurantRepository = restaurantRepository,
        super(ProductLoading()) {
    on<LoadProducts>(_onLoadProducts);
    on<FilterProducts>(_onFilterProducts);
    on<SortProducts>(_onSortProducts);
    on<AddProduct>(_onAddProduct);

    _categorySubscription = _categoryBloc.stream.listen((state) {
      if (state is CategoryLoaded && state.selectedCategory != null) {
        add(
          FilterProducts(
            category: (state.selectedCategory!),
          ),
        );
      } else {}
    });
    _restaurantSubscription =
        _restaurantRepository.getRestaurant().listen((restaurant) {
      add(LoadProducts(products: restaurant.products!));
    });
  }

  void _onLoadProducts(
    LoadProducts event,
    Emitter<ProductState> emit,
  ) async {
    await Future<void>.delayed(const Duration(seconds: 1));
    emit(ProductLoaded(products: event.products));
  }

  void _onFilterProducts(
    FilterProducts event,
    Emitter<ProductState> emit,
  ) async {
    await Future<void>.delayed(const Duration(seconds: 1));

    List<Product> filteredProducts = Product.products
        .where((product) => product.category == event.category.name)
        .toList();

    emit(ProductLoaded(products: filteredProducts));
  }

  void _onSortProducts(
    SortProducts event,
    Emitter<ProductState> emit,
  ) async {
    final state = this.state as ProductLoaded;
    emit(ProductLoading());
    await Future<void>.delayed(const Duration(seconds: 1));

    int newIndex =
        (event.newIndex > event.oldIndex) ? event.newIndex - 1 : event.newIndex;

    try {
      Product selectedProduct = state.products[event.oldIndex];

      List<Product> sortedProducts = List.from(state.products)
        ..remove(selectedProduct)
        ..insert(newIndex, selectedProduct);

      emit(
        ProductLoaded(products: sortedProducts),
      );
    } catch (_) {}
  }

  void _onAddProduct(AddProduct event, Emitter<ProductState> emit) async {
    if (state is ProductLoaded) {
      List<Product> newProducts = List.from((state as ProductLoaded).products)
        ..add(event.product);
      _restaurantRepository.editProducts(newProducts);
      emit(ProductLoaded(products: newProducts));
    }
  }

  @override
  Future<void> close() async {
    _categorySubscription?.cancel();
    _restaurantSubscription?.cancel();
    super.close();
  }
}
