import 'package:flutter/material.dart';
import '../services/nike_api2.dart';

class LiveProductsScreen extends StatefulWidget {
  const LiveProductsScreen({Key? key}) : super(key: key);

  @override
  State<LiveProductsScreen> createState() => _LiveProductsScreenState();
}

class _LiveProductsScreenState extends State<LiveProductsScreen> {
  final List<NikeProduct> _products = [];
  String? _nextToken;
  bool _loading = false;
  String? _error;
  final ScrollController _sc = ScrollController();

  // filtros activos
  final List<String> _activeFilters = [];

  @override
  void initState() {
    super.initState();
    _sc.addListener(_onScroll);
    _loadInitial(saveRaw: true);
  }

  @override
  void dispose() {
    _sc.removeListener(_onScroll);
    _sc.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_sc.position.extentAfter < 300 && !_loading && _nextToken != null) {
      _loadMore();
    }
  }

  Future<void> _loadInitial({bool saveRaw = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await NikeApi.fetchProducts(
        categoriesFilter: _activeFilters.isEmpty ? null : _activeFilters,
        saveRawToProject: saveRaw, // guarda JSON crudo la primera vez si saveRaw true
        saveFiltered: false,
      );
      setState(() {
        _products.clear();
        _products.addAll(res.items);
        _nextToken = res.nextToken;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_nextToken == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await NikeApi.fetchProducts(
        nextToken: _nextToken,
        categoriesFilter: _activeFilters.isEmpty ? null : _activeFilters,
      );
      setState(() {
        _products.addAll(res.items);
        _nextToken = res.nextToken;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    await _loadInitial();
  }

  void _toggleFilter(String name) {
    setState(() {
      if (_activeFilters.contains(name)) {
        _activeFilters.remove(name);
      } else {
        _activeFilters.add(name);
      }
      // recargar (ten cuidado con el límite de requests: sólo llama cuando el usuario cambia filtro)
      _loadInitial(saveRaw: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Nike Products'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Running'),
                  selected: _activeFilters.contains('running'),
                  onSelected: (_) => _toggleFilter('running'),
                ),
                FilterChip(
                  label: const Text('Football'),
                  selected: _activeFilters.contains('football'),
                  onSelected: (_) => _toggleFilter('football'),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: _error != null && _products.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text('Error: $_error'),
                          ),
                        )
                      ],
                    )
                  : GridView.builder(
                      controller: _sc,
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.72,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _products.length + (_nextToken != null ? 1 : 0),
                      itemBuilder: (context, i) {
                        if (i >= _products.length) {
                          return Center(
                            child: _loading
                                ? const CircularProgressIndicator()
                                : ElevatedButton(
                                    onPressed: _loadMore,
                                    child: const Text('Cargar más'),
                                  ),
                          );
                        }
                        final p = _products[i];
                        return Card(
                          clipBehavior: Clip.hardEdge,
                          child: InkWell(
                            onTap: () => debugPrint('Open: ${p.productUrl}'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: p.imageUrl.isNotEmpty
                                      ? Image.network(
                                          p.imageUrl,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                                        )
                                      : const Center(child: Icon(Icons.image_not_supported)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(p.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
                                  child: Text(p.price, style: const TextStyle(color: Colors.green)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: _products.isEmpty && _loading ? null : FloatingActionButton(
        onPressed: _onRefresh,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}