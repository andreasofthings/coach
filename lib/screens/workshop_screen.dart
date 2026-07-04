import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/workshop_provider.dart';
import '../models/workshop.dart';

class WorkshopScreen extends StatefulWidget {
  const WorkshopScreen({super.key});

  @override
  State<WorkshopScreen> createState() => _WorkshopScreenState();
}

class _WorkshopScreenState extends State<WorkshopScreen> {
  final TextEditingController _searchController = TextEditingController();

  void _showFilterSheet(BuildContext context) {
    final provider = context.read<WorkshopProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final colorScheme = Theme.of(context).colorScheme;
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppLocalizations.of(context)!.filters, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {
                          provider.clearFilters();
                          setModalState(() {});
                        },
                        child: Text(AppLocalizations.of(context)!.clearAll),
                      ),
                    ],
                  ),
                  const Divider(),
                  Text(AppLocalizations.of(context)!.sortBy, style: const TextStyle(fontWeight: FontWeight.bold)),
                  RadioListTile<WorkshopSort>(
                    title: Text(AppLocalizations.of(context)!.sortDateNewest),
                    value: WorkshopSort.dateNewest,
                    groupValue: provider.currentSort,
                    onChanged: (val) {
                      provider.setSort(val!);
                      setModalState(() {});
                    },
                  ),
                  RadioListTile<WorkshopSort>(
                    title: Text(AppLocalizations.of(context)!.sortDateOldest),
                    value: WorkshopSort.dateOldest,
                    groupValue: provider.currentSort,
                    onChanged: (val) {
                      provider.setSort(val!);
                      setModalState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.status, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 8,
                    children: WorkshopStatus.values.map((status) {
                      final isSelected = provider.statusFilter == status;
                      return ChoiceChip(
                        label: Text(status.label),
                        selected: isSelected,
                        onSelected: (selected) {
                          provider.setStatusFilter(selected ? status : null);
                          setModalState(() {});
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.locationMode, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 8,
                    children: LocationMode.values.map((mode) {
                      final isSelected = provider.locationFilter == mode;
                      return ChoiceChip(
                        label: Text(mode.label),
                        selected: isSelected,
                        onSelected: (selected) {
                          provider.setLocationFilter(selected ? mode : null);
                          setModalState(() {});
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(AppLocalizations.of(context)!.apply),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCreateDialog(BuildContext context) {
    final titleController = TextEditingController();
    final participantsController = TextEditingController();
    final durationController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    LocationMode selectedMode = LocationMode.virtual;
    DurationUnit selectedUnit = DurationUnit.minutes;
    String workshopType = 'design-thinking';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.createWorkshop),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(labelText: AppLocalizations.of(context)!.title),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<LocationMode>(
                      value: selectedMode,
                      decoration: InputDecoration(labelText: AppLocalizations.of(context)!.locationMode),
                      items: LocationMode.values.map((mode) {
                        return DropdownMenuItem(value: mode, child: Text(mode.label));
                      }).toList(),
                      onChanged: (val) => setDialogState(() => selectedMode = val!),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: TextEditingController(text: workshopType),
                      decoration: InputDecoration(labelText: AppLocalizations.of(context)!.workshopType),
                      onChanged: (val) => workshopType = val,
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(AppLocalizations.of(context)!.dateLabel(DateFormat('MMM dd, yyyy').format(selectedDate))),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setDialogState(() => selectedDate = date);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: durationController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(labelText: AppLocalizations.of(context)!.duration),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<DurationUnit>(
                            value: selectedUnit,
                            items: DurationUnit.values.map((unit) {
                              return DropdownMenuItem(value: unit, child: Text(unit.label));
                            }).toList(),
                            onChanged: (val) => setDialogState(() => selectedUnit = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: participantsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: AppLocalizations.of(context)!.participants),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    final workshop = Workshop(
                      id: '',
                      title: titleController.text,
                      locationMode: selectedMode,
                      workshopType: workshopType,
                      status: WorkshopStatus.planned,
                      date: selectedDate,
                      durationValue: int.tryParse(durationController.text) ?? 0,
                      durationUnit: selectedUnit,
                      participantCount: int.tryParse(participantsController.text) ?? 0,
                    );
                    context.read<WorkshopProvider>().addWorkshop(workshop);
                    Navigator.pop(context);
                  },
                  child: Text(AppLocalizations.of(context)!.create),
                ),
              ],
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
      body: SafeArea(
        child: Column(
          children: [
            // Stitch Header Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.workshopPlanner,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppLocalizations.of(context)!.workshopPlannerSubtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => _showCreateDialog(context),
                    borderRadius: BorderRadius.circular(99),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.add,
                        color: colorScheme.onPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.searchSessionsHint,
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHigh.withOpacity(0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (val) {
                  // Implement search or dynamic filtering if desired
                },
              ),
            ),
            const SizedBox(height: 12),

            // Horizontal Filters Row (Stitch-inspired)
            Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 8),
              child: Consumer<WorkshopProvider>(
                builder: (context, provider, child) {
                  final activeStatus = provider.statusFilter;

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        _buildFilterButton(
                          context,
                          label: AppLocalizations.of(context)!.allWorkshops,
                          isSelected: activeStatus == null,
                          onPressed: () {
                            provider.setStatusFilter(null);
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildFilterButton(
                          context,
                          label: AppLocalizations.of(context)!.upcoming,
                          isSelected: activeStatus == WorkshopStatus.planned,
                          onPressed: () {
                            provider.setStatusFilter(WorkshopStatus.planned);
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildFilterButton(
                          context,
                          label: AppLocalizations.of(context)!.past,
                          isSelected: activeStatus == WorkshopStatus.delivered,
                          onPressed: () {
                            provider.setStatusFilter(WorkshopStatus.delivered);
                          },
                        ),
                        const SizedBox(width: 8),
                        _buildFilterButton(
                          context,
                          label: AppLocalizations.of(context)!.filters,
                          isSelected: provider.locationFilter != null,
                          icon: Icons.tune,
                          onPressed: () => _showFilterSheet(context),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1),

            // Bento Cards List
            Expanded(
              child: Consumer<WorkshopProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading && provider.workshops.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final workshops = provider.workshops;
                  if (workshops.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: workshops.length,
                    itemBuilder: (context, index) {
                      return _buildStitchWorkshopCard(context, workshops[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterButton(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onPressed,
    IconData? icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: isSelected ? colorScheme.primary.withOpacity(0.2) : colorScheme.outlineVariant.withOpacity(0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStitchWorkshopCard(BuildContext context, Workshop workshop) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPlanned = workshop.status == WorkshopStatus.planned;

    IconData locationIcon;
    Color modeColor;

    switch (workshop.locationMode) {
      case LocationMode.virtual:
        locationIcon = Icons.videocam;
        modeColor = colorScheme.tertiary;
        break;
      case LocationMode.onSite:
        locationIcon = Icons.location_on;
        modeColor = colorScheme.primary;
        break;
      case LocationMode.hybrid:
        locationIcon = Icons.devices;
        modeColor = colorScheme.secondary;
        break;
    }

    return Dismissible(
      key: Key(workshop.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.delete, color: colorScheme.onError),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.deleteWorkshop),
            content: Text(AppLocalizations.of(context)!.deleteWorkshopConfirm),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppLocalizations.of(context)!.cancel)),
              TextButton(onPressed: () => Navigator.pop(context, true), child: Text(AppLocalizations.of(context)!.delete)),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        context.read<WorkshopProvider>().deleteWorkshop(workshop.id);
      },
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/workshop-detail', arguments: workshop),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorScheme.outlineVariant.withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                // Left Indicator Strip
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 4,
                  child: Container(
                    color: isPlanned ? colorScheme.primary : colorScheme.outlineVariant,
                  ),
                ),
                // Card Contents
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Badges & Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              // Workshop Type Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  workshop.workshopType.replaceAll('-', ' ').toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Location Mode Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: modeColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(locationIcon, size: 10, color: modeColor),
                                    const SizedBox(width: 3),
                                    Text(
                                      workshop.locationMode.label,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                        color: modeColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // Status Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPlanned ? colorScheme.secondaryContainer : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              workshop.status.label,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                color: isPlanned ? colorScheme.onSecondaryContainer : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Title
                      Text(
                        workshop.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Details: Date & Time/Participants
                      Row(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 14, color: colorScheme.onSurfaceVariant.withOpacity(0.6)),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('MMM dd, yyyy').format(workshop.date),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Row(
                            children: [
                              Icon(
                                isPlanned ? Icons.schedule : Icons.group,
                                size: 14,
                                color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isPlanned
                                    ? '${workshop.durationValue} ${workshop.durationUnit.label}'
                                    : AppLocalizations.of(context)!.participantsCount(workshop.participantCount),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 8),

                      // Footer: Avatars Stack & Detail Action
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Avatars (overlapping representation)
                          Row(
                            children: [
                              _buildOverlappingAvatar(context, 'JD', 0),
                              _buildOverlappingAvatar(context, 'SM', 1),
                              if (workshop.participantCount > 2)
                                _buildOverlappingAvatar(context, '+${workshop.participantCount - 2}', 2),
                            ],
                          ),
                          // View Action Indicator
                          Row(
                            children: [
                              if (!isPlanned)
                                Text(
                                  AppLocalizations.of(context)!.viewOutcomes,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.secondary,
                                  ),
                                ),
                              Icon(
                                Icons.chevron_right,
                                size: 18,
                                color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlappingAvatar(BuildContext context, String initials, int index) {
    final colorScheme = Theme.of(context).colorScheme;

    return Transform.translate(
      offset: Offset(index * -6.0, 0),
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: colorScheme.surfaceContainerLowest,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.event_available, size: 48, color: colorScheme.outline),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.organizeSessionsSubtitle,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.organizeSessionsDetail,
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.outline, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
