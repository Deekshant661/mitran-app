import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dog_filters.dart';
import '../models/dog_model.dart';
import 'dogs_provider.dart';

// Filter State Provider
final dogFiltersProvider = StateProvider<DogFilters>((ref) {
  return DogFilters(
    vaccinated: false,
    sterilized: false,
    readyForAdoption: false,
  );
});

// Search Term Provider
final searchTermProvider = StateProvider<String>((ref) => '');

// Filtered Dogs Provider
final filteredDogsProvider = Provider<List<DogModel>>((ref) {
  final dogs = ref.watch(dogsProvider).value ?? [];
  final filters = ref.watch(dogFiltersProvider);
  final searchTerm = ref.watch(searchTermProvider);
  
  return dogs.where((dog) {
    // Search filter
    if (searchTerm.isNotEmpty) {
      final matchesName = dog.name.toLowerCase().contains(searchTerm.toLowerCase());
      final matchesArea = dog.area.toLowerCase().contains(searchTerm.toLowerCase());
      if (!matchesName && !matchesArea) return false;
    }
    
    // Status filters
    if (filters.vaccinated && !dog.vaccinationStatus) return false;
    if (filters.sterilized && !dog.sterilizationStatus) return false;
    if (filters.readyForAdoption && !dog.readyForAdoption) return false;
    
    return true;
  }).toList();
});