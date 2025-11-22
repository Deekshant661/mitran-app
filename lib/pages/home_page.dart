import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/custom_bottom_nav.dart';
import '../widgets/post_card.dart';
import '../widgets/custom_card.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_buttons.dart';
import '../utils/animations.dart';
import '../providers/posts_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../services/firestore_service.dart';
import '../models/post_model.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final TextEditingController _postController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<void> _createPost() async {
    final content = _postController.text.trim();
    if (content.isEmpty || content.length > 500) return;

    try {
      // Get current user from auth provider
      final user = ref.read(authProvider).value;
      if (user == null) return;

      // Get user profile
      final userProfile = await ref.read(userProfileProvider(user.uid).future);

      final post = PostModel(
        postId: '',
        content: content,
        author: PostAuthor(
          userId: user.uid,
          username: userProfile.username,
          profilePictureUrl: userProfile.profilePictureUrl,
        ),
        timestamp: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await _firestoreService.createPost(post, user.uid);
      
      _postController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post created successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating post: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(postsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('The Mitran Hub'),
        centerTitle: true,
      ),
      body: SafeArea(child: Column(
        children: [
          // Create Post Section
          FadeInAnimation(
            child: CustomCard(
              margin: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Consumer(
                    builder: (context, ref, child) {
                      final user = ref.watch(authProvider).value;
                      if (user == null) return const SizedBox.shrink();
                      final userProfileAsync = ref.watch(userProfileProvider(user.uid));
                      return userProfileAsync.when(
                        data: (userProfile) {
                          return CircleAvatar(
                            radius: 20,
                            backgroundImage: userProfile.profilePictureUrl.isNotEmpty
                                ? NetworkImage(userProfile.profilePictureUrl)
                                : null,
                            child: userProfile.profilePictureUrl.isEmpty
                                ? Text(userProfile.username.substring(0, 1).toUpperCase())
                                : null,
                          );
                        },
                        loading: () => const CircleAvatar(radius: 20),
                        error: (_, __) => const CircleAvatar(radius: 20),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        CustomTextField(
                          controller: _postController,
                          hint: "What's happening, Guardian?",
                          maxLines: 3,
                          maxLength: 500,
                        ),
                        const SizedBox(height: 8),
                        PrimaryButton(text: 'Post', onPressed: _createPost, width: 120),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Posts Feed
          Expanded(
            child: postsAsync.when(
              data: (posts) {
                if (posts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.post_add,
                          size: 64,
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text('No posts yet. Be the first to share!',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                      ],
                    ),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(postsProvider);
                  },
                  child: ListView.builder(
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      return SlideInAnimation(
                        delay: Duration(milliseconds: 60 * index),
                        child: PostCard(post: posts[index]),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error loading posts: $error'),
              ),
            ),
          ),
        ],
      )),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 0),
    );
  }
}