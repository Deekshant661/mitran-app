class DogFilters {
  final bool vaccinated;
  final bool sterilized;
  final bool readyForAdoption;

  DogFilters({
    required this.vaccinated,
    required this.sterilized,
    required this.readyForAdoption,
  });

  DogFilters copyWith({
    bool? vaccinated,
    bool? sterilized,
    bool? readyForAdoption,
  }) {
    return DogFilters(
      vaccinated: vaccinated ?? this.vaccinated,
      sterilized: sterilized ?? this.sterilized,
      readyForAdoption: readyForAdoption ?? this.readyForAdoption,
    );
  }

  bool get hasActiveFilters =>
      vaccinated || sterilized || readyForAdoption;

  // Clear all filters
  DogFilters clearFilters() => DogFilters(
    vaccinated: false,
    sterilized: false,
    readyForAdoption: false,
  );
}