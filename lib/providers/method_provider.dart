import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/method.dart';

enum MethodSort {
  alphabeticalAsc,
  alphabeticalDesc,
  dateLatest,
  dateOldest,
}

class MethodProvider extends ChangeNotifier {
  List<Method> _allMethods = [];
  List<Method> _filteredMethods = [];
  bool _isLoading = false;
  bool _hasError = false;

  String _searchQuery = '';
  Set<String> _selectedTags = {};
  Set<String> _selectedMethodTypes = {};
  int _minPeopleFilter = 0;
  int _maxPeopleFilter = 50;
  int _minTimeFilter = 0;
  int _maxTimeFilter = 180;
  MethodSort _currentSort = MethodSort.alphabeticalAsc;

  MethodProvider() {
    fetchMethods();
  }

  List<Method> get methods => _filteredMethods;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get searchQuery => _searchQuery;
  Set<String> get selectedTags => _selectedTags;
  Set<String> get selectedMethodTypes => _selectedMethodTypes;
  int get minPeopleFilter => _minPeopleFilter;
  int get maxPeopleFilter => _maxPeopleFilter;
  int get minTimeFilter => _minTimeFilter;
  int get maxTimeFilter => _maxTimeFilter;
  MethodSort get currentSort => _currentSort;

  List<String> get availableTags {
    final tags = _allMethods.expand((m) => m.tags).toSet().toList();
    tags.sort();
    return tags;
  }

  List<String> get availableMethodTypes {
    final types = _allMethods.map((m) => m.methodType).toSet().toList();
    types.sort();
    return types;
  }

  String get _cmsToken => const String.fromEnvironment('PRAMARI_CMS_TOKEN');

  Future<void> fetchMethods() async {
    _isLoading = true;
    _hasError = false;
    notifyListeners();

    try {
      final fields = 'title,date,benefit,method_input,method_output,why,how,tags,method_type,min_people,max_people,min_time,max_time';
      final url = 'https://pramari.de/api/v2/pages/?type=pages.MethodPage&fields=$fields';

      final Map<String, String> headers = {};
      if (_cmsToken.isNotEmpty) {
        headers['Authorization'] = 'Token $_cmsToken';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> items = data['items'] ?? [];
        _allMethods = items.map((item) => Method.fromJson(item)).toList();
        _applyFiltersAndSort();
        _hasError = false;
      } else {
        debugPrint('Failed to fetch methods: ${response.statusCode} ${response.body}');
        _hasError = true;
      }
    } catch (e) {
      debugPrint('Error fetching methods: $e');
      _hasError = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFiltersAndSort();
  }

  void toggleTag(String tag) {
    if (_selectedTags.contains(tag)) {
      _selectedTags.remove(tag);
    } else {
      _selectedTags.add(tag);
    }
    _applyFiltersAndSort();
  }

  void toggleMethodType(String type) {
    if (_selectedMethodTypes.contains(type)) {
      _selectedMethodTypes.remove(type);
    } else {
      _selectedMethodTypes.add(type);
    }
    _applyFiltersAndSort();
  }

  void setPeopleRange(int min, int max) {
    _minPeopleFilter = min;
    _maxPeopleFilter = max;
    _applyFiltersAndSort();
  }

  void setTimeRange(int min, int max) {
    _minTimeFilter = min;
    _maxTimeFilter = max;
    _applyFiltersAndSort();
  }

  void setSort(MethodSort sort) {
    _currentSort = sort;
    _applyFiltersAndSort();
  }


  void applyAllFilters({
    Set<String>? selectedMethodTypes,
    int? minPeople,
    int? maxPeople,
    int? minTime,
    int? maxTime,
    MethodSort? sort,
  }) {
    if (selectedMethodTypes != null) _selectedMethodTypes = Set.from(selectedMethodTypes);
    if (minPeople != null) _minPeopleFilter = minPeople;
    if (maxPeople != null) _maxPeopleFilter = maxPeople;
    if (minTime != null) _minTimeFilter = minTime;
    if (maxTime != null) _maxTimeFilter = maxTime;
    if (sort != null) _currentSort = sort;
    _applyFiltersAndSort();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedTags = {};
    _selectedMethodTypes = {};
    _minPeopleFilter = 0;
    _maxPeopleFilter = 50;
    _minTimeFilter = 0;
    _maxTimeFilter = 180;
    _applyFiltersAndSort();
  }

  void _applyFiltersAndSort() {
    _filteredMethods = _allMethods.where((method) {
      final matchesSearch = method.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          method.benefit.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesTags = _selectedTags.isEmpty ||
          _selectedTags.every((tag) => method.tags.contains(tag));

      final matchesType = _selectedMethodTypes.isEmpty ||
          _selectedMethodTypes.contains(method.methodType);

      // People filter: overlapping ranges
      // If method has no min/max, we assume it's always included?
      // Or if it has min/max, it must overlap with the filter range.
      bool matchesPeople = true;
      if (method.minPeople != null || method.maxPeople != null) {
        final mMin = method.minPeople ?? 0;
        final mMax = method.maxPeople ?? 999;
        matchesPeople = !(mMax < _minPeopleFilter || mMin > _maxPeopleFilter);
      }

      bool matchesTime = true;
      if (method.minTime != null || method.maxTime != null) {
        final mMin = method.minTime ?? 0;
        final mMax = method.maxTime ?? 999;
        matchesTime = !(mMax < _minTimeFilter || mMin > _maxTimeFilter);
      }

      return matchesSearch && matchesTags && matchesType && matchesPeople && matchesTime;
    }).toList();

    switch (_currentSort) {
      case MethodSort.alphabeticalAsc:
        _filteredMethods.sort((a, b) => a.title.compareTo(b.title));
        break;
      case MethodSort.alphabeticalDesc:
        _filteredMethods.sort((a, b) => b.title.compareTo(a.title));
        break;
      case MethodSort.dateLatest:
        _filteredMethods.sort((a, b) {
          if (a.date == null && b.date == null) return 0;
          if (a.date == null) return 1;
          if (b.date == null) return -1;
          return b.date!.compareTo(a.date!);
        });
        break;
      case MethodSort.dateOldest:
        _filteredMethods.sort((a, b) {
          if (a.date == null && b.date == null) return 0;
          if (a.date == null) return 1;
          if (b.date == null) return -1;
          return a.date!.compareTo(b.date!);
        });
        break;
    }

    notifyListeners();
  }
}
