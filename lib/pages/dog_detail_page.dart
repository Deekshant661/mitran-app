import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dog_model.dart';
import '../providers/dogs_provider.dart';

class DogDetailPage extends ConsumerStatefulWidget {
  final String dogId;

  const DogDetailPage({super.key, required this.dogId});

  @override
  ConsumerState<DogDetailPage> createState() => _DogDetailPageState();
}

class _DogDetailPageState extends ConsumerState<DogDetailPage> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _shareDog() {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon!')),
    );
  }

  void _reportDog() {
    // TODO: Implement report functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Report functionality coming soon!')),
    );
  }

  void _editDog() {
    // TODO: Navigate to edit dog page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit functionality coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dogAsync = ref.watch(dogProvider(widget.dogId));

    return dogAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) =>
          const Scaffold(body: Center(child: Text('Failed to load dog'))),
      data: (dog) => Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (dog.photos.isNotEmpty)
                      PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                        itemCount: dog.photos.length,
                        itemBuilder: (context, index) {
                          return Image.network(
                            dog.photos[index],
                            fit: BoxFit.cover,
                          );
                        },
                      )
                    else
                      Container(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        child: Icon(
                          Icons.pets,
                          size: 100,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                      ),
                    if (dog.photos.length > 1)
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            dog.photos.length,
                            (index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentImageIndex == index
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: _shareDog,
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'report':
                        _reportDog();
                        break;
                      case 'edit':
                        _editDog();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'report', child: Text('Report')),
                    if (dog.addedBy.userId == 'currentUserId')
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  ],
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dog.name,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              if (dog.temperament.isNotEmpty)
                                Text(
                                  dog.temperament,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.7),
                                      ),
                                ),
                            ],
                          ),
                        ),
                        if ((dog.qrCodeId ?? '').isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.qr_code,
                                  size: 20,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Tagged',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (dog.vaccinationStatus)
                          _StatusChip(label: 'Vaccinated', color: Colors.green),
                        if (dog.sterilizationStatus)
                          _StatusChip(label: 'Sterilized', color: Colors.blue),
                        if (dog.readyForAdoption)
                          _StatusChip(label: 'Ready for Adoption', color: Colors.orange),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if ((dog.qrCodeId ?? '').isNotEmpty) ...[
                      _InfoSection(
                        icon: Icons.qr_code_2,
                        title: 'MITRAN ID',
                        content: dog.qrCodeId!,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if ((dog.area.isNotEmpty) || (dog.city.isNotEmpty)) ...[
                      _InfoSection(
                        icon: Icons.location_on_outlined,
                        title: 'Location',
                        content: [
                          dog.area,
                          dog.city,
                        ].where((s) => s.isNotEmpty).join(', '),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (dog.temperament.isNotEmpty) ...[
                      _InfoSection(
                        icon: Icons.psychology_outlined,
                        title: 'Temperament',
                        content: dog.temperament,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (dog.healthNotes.isNotEmpty) ...[
                      _InfoSection(
                        icon: Icons.note_alt_outlined,
                        title: 'Health Notes',
                        content: dog.healthNotes,
                      ),
                      const SizedBox(height: 16),
                    ],
                    _AddedBySection(dog: dog),
                    const SizedBox(height: 24),
                    if (dog.readyForAdoption)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Adoption Contact',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              _InfoSection(
                                icon: Icons.person_outline,
                                title: 'Contact',
                                content: dog.addedBy.username,
                              ),
                              const SizedBox(height: 8),
                              _InfoSection(
                                icon: Icons.email_outlined,
                                title: 'Email',
                                content: dog.addedBy.contactInfo.email,
                              ),
                              const SizedBox(height: 8),
                              _InfoSection(
                                icon: Icons.phone_outlined,
                                title: 'Phone',
                                content: dog.addedBy.contactInfo.phone,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const _InfoSection({
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(content, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }
}

class _AddedBySection extends StatelessWidget {
  final DogModel dog;

  const _AddedBySection({required this.dog});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          child: Text(
            dog.addedBy.username.substring(0, 1).toUpperCase(),
            style: const TextStyle(fontSize: 12),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Added by ${dog.addedBy.username}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
              Text(
                'Added on ${_formatDate(dog.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
