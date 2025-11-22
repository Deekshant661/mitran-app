import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/dog_card.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/filter_chip.dart';
import '../providers/dogs_provider.dart';
import '../providers/filters_provider.dart';

class DirectoryPage extends ConsumerStatefulWidget {
  const DirectoryPage({super.key});

  @override
  ConsumerState<DirectoryPage> createState() => _DirectoryPageState();
}

class _DirectoryPageState extends ConsumerState<DirectoryPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    ref.read(searchTermProvider.notifier).state = query;
  }

  // Filters inline via chips per PRD; no modal filters

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mitran Directory'),
        centerTitle: true,
      ),
      body: SafeArea(child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: SearchField(
              controller: _searchController,
              hint: 'Search Mitran records by name or area...'
            ),
          ),
          // PRD filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Consumer(
              builder: (context, ref, child) {
                final filters = ref.watch(dogFiltersProvider);
                return FilterChipsRow(
                  vaccinated: filters.vaccinated,
                  sterilized: filters.sterilized,
                  adoptable: filters.readyForAdoption,
                  onFilterChanged: (key) {
                    final f = ref.read(dogFiltersProvider);
                    switch (key) {
                      case 'vaccinated':
                        ref.read(dogFiltersProvider.notifier).state = f.copyWith(vaccinated: !f.vaccinated);
                        break;
                      case 'sterilized':
                        ref.read(dogFiltersProvider.notifier).state = f.copyWith(sterilized: !f.sterilized);
                        break;
                      case 'adoptable':
                        ref.read(dogFiltersProvider.notifier).state = f.copyWith(readyForAdoption: !f.readyForAdoption);
                        break;
                    }
                  },
                  onClearAll: () {
                    final f = ref.read(dogFiltersProvider);
                    if (f.vaccinated || f.sterilized || f.readyForAdoption) {
                      ref.read(dogFiltersProvider.notifier).state = f.copyWith(
                        vaccinated: false,
                        sterilized: false,
                        readyForAdoption: false,
                      );
                    }
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          // Dogs list
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final dogsAsync = ref.watch(dogsProvider);
                final filteredDogs = ref.watch(filteredDogsProvider);
                
                return dogsAsync.when(
                  data: (_) {
                    if (filteredDogs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.pets,
                              size: 64,
                              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No dogs found',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your search or filters',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(dogsProvider);
                      },
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: filteredDogs.length,
                        itemBuilder: (context, index) {
                          final dog = filteredDogs[index];
                          return DogCard(
                            dog: dog,
                            onTap: () => context.push('/directory/${dog.dogId}'),
                          );
                        },
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text('Error loading dogs: $error'),
                  ),
                );
              },
            ),
          ),
        ],
      )),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/qr-scanner'),
        child: const Icon(Icons.qr_code_scanner),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 1),
    );
  }
}

// Removed non-PRD filter bottom sheet and chips