import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/method_provider.dart';
import '../widgets/method_square_card.dart';
import 'method_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterSheet(BuildContext context) {
    final provider = context.read<MethodProvider>();

    // Local state for the filter sheet
    Set<String> localSelectedTypes = Set.from(provider.selectedMethodTypes);
    RangeValues localPeopleRange = RangeValues(
      provider.minPeopleFilter.toDouble(),
      provider.maxPeopleFilter.toDouble(),
    );
    RangeValues localTimeRange = RangeValues(
      provider.minTimeFilter.toDouble(),
      provider.maxTimeFilter.toDouble(),
    );
    MethodSort localSort = provider.currentSort;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Filters', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          TextButton(
                            onPressed: () {
                              setModalState(() {
                                localSelectedTypes.clear();
                                localPeopleRange = const RangeValues(0, 50);
                                localTimeRange = const RangeValues(0, 180);
                                localSort = MethodSort.alphabeticalAsc;
                              });
                            },
                            child: const Text('Clear All'),
                          ),
                        ],
                      ),
                      const Divider(),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: [
                            const Text('Method Type', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: provider.availableMethodTypes.map((type) {
                                final isSelected = localSelectedTypes.contains(type);
                                return FilterChip(
                                  label: Text(type),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setModalState(() {
                                      if (selected) {
                                        localSelectedTypes.add(type);
                                      } else {
                                        localSelectedTypes.remove(type);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Participants: ${localPeopleRange.start.round()} - ${localPeopleRange.end.round()}' ,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            RangeSlider(
                              values: localPeopleRange,
                              min: 0,
                              max: 50,
                              divisions: 50,
                              labels: RangeLabels(
                                localPeopleRange.start.round().toString(),
                                localPeopleRange.end.round().toString(),
                              ),
                              onChanged: (values) {
                                setModalState(() {
                                  localPeopleRange = values;
                                });
                              },
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Duration: ${localTimeRange.start.round()} - ${localTimeRange.end.round()} min',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            RangeSlider(
                              values: localTimeRange,
                              min: 0,
                              max: 180,
                              divisions: 36,
                              labels: RangeLabels(
                                localTimeRange.start.round().toString(),
                                localTimeRange.end.round().toString(),
                              ),
                              onChanged: (values) {
                                setModalState(() {
                                  localTimeRange = values;
                                });
                              },
                            ),
                            const SizedBox(height: 24),
                            const Text('Sort By', style: TextStyle(fontWeight: FontWeight.bold)),
                            ...MethodSort.values.map((sort) {
                              String label = '';
                              switch (sort) {
                                case MethodSort.alphabeticalAsc: label = 'Alphabetical (A-Z)'; break;
                                case MethodSort.alphabeticalDesc: label = 'Alphabetical (Z-A)'; break;
                                case MethodSort.dateLatest: label = 'Latest'; break;
                                case MethodSort.dateOldest: label = 'Oldest'; break;
                              }
                              return RadioListTile<MethodSort>(
                                title: Text(label),
                                value: sort,
                                groupValue: localSort,
                                onChanged: (value) {
                                  if (value != null) {
                                    setModalState(() {
                                      localSort = value;
                                    });
                                  }
                                },
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            provider.applyAllFilters(
                              selectedMethodTypes: localSelectedTypes,
                              minPeople: localPeopleRange.start.round(),
                              maxPeople: localPeopleRange.end.round(),
                              minTime: localTimeRange.start.round(),
                              maxTime: localTimeRange.end.round(),
                              sort: localSort,
                            );
                            Navigator.pop(context);
                          },
                          child: const Text('Apply Filters'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LIBRARY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: colorScheme.primary,
                      ),
                    ),
                    const Text(
                      'METHOD TOOLKIT',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.tune),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.surfaceContainerHigh,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  ),
                  onPressed: () => _showFilterSheet(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search methods...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: colorScheme.surfaceContainerHigh,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (val) => context.read<MethodProvider>().setSearchQuery(val),
            ),
          ),
          // Category chips
          Consumer<MethodProvider>(
            builder: (context, provider, child) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildCategoryChip(
                      'All',
                      provider.selectedMethodTypes.isEmpty,
                      onTap: () => provider.applyAllFilters(selectedMethodTypes: {}),
                    ),
                    ...provider.availableMethodTypes.map((type) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: _buildCategoryChip(
                          type,
                          provider.selectedMethodTypes.contains(type),
                          onTap: () => provider.toggleMethodType(type),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
          const Divider(height: 1),
          Expanded(
            child: Consumer<MethodProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.methods.isEmpty) {
                  return const Center(child: Text('No methods found.'));
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    double horizontalPadding = 16.0;
                    double availableWidth = constraints.maxWidth - 2 * horizontalPadding;
                    int crossAxisCount = ((availableWidth + 12) / (240 + 12)).floor().clamp(1, 4);

                    // Ensure cards don't exceed 480px
                    double gridWidth = availableWidth;
                    double cardWidth = (availableWidth - (crossAxisCount - 1) * 12) / crossAxisCount;
                    if (cardWidth > 480) {
                      cardWidth = 480;
                      gridWidth = crossAxisCount * 480 + (crossAxisCount - 1) * 12;
                    }

                    return Center(
                      child: SizedBox(
                        width: gridWidth + 2 * horizontalPadding,
                        child: GridView.builder(
                          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: provider.methods.length,
                          itemBuilder: (context, index) {
                            final method = provider.methods[index];
                            return MethodSquareCard(
                              method: method,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MethodDetailScreen(method: method),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    );
                  }
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected, {VoidCallback? onTap}) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(0),
        ),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}
