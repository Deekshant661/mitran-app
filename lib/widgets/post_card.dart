import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../utils/date_formatter.dart';
import '../widgets/custom_card.dart';

class PostCard extends StatelessWidget {
  final PostModel post;

  const PostCard({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author info
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: post.author.profilePictureUrl.isNotEmpty
                      ? NetworkImage(post.author.profilePictureUrl)
                      : null,
                  child: post.author.profilePictureUrl.isEmpty
                      ? Text(
                          post.author.username.substring(0, 1).toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.author.username,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        DateFormatter.getRelativeTime(post.timestamp),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () => _showPostOptions(context),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Post content
            Text(
              post.content,
              style: Theme.of(context).textTheme.bodyLarge,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
          ],
        ),
    );
  }

  void _showPostOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.report_outlined),
            title: const Text('Report Post'),
            onTap: () {
              Navigator.pop(context);
              _reportPost();
            },
          ),
          ListTile(
            leading: const Icon(Icons.block_outlined),
            title: const Text('Block User'),
            onTap: () {
              Navigator.pop(context);
              _blockUser();
            },
          ),
          if (post.author.userId ==
              'currentUserId') // TODO: Replace with actual current user ID
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                'Delete Post',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _deletePost();
              },
            ),
        ],
      ),
    );
  }

  void _reportPost() {
    // TODO: Implement report functionality
  }

  void _blockUser() {
    // TODO: Implement block user functionality
  }

  void _deletePost() {
    // TODO: Implement delete post functionality
  }
}
