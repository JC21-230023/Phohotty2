import 'package:flutter/material.dart';



class PostCard extends StatefulWidget {
  const PostCard({
    super.key,
    required this.docId,
    required this.title,
    required this.imageUrl,
    required this.tagList,
  });

  final String docId;
  final String title;
  final String imageUrl;
  final String tagList;

  @override
  State<PostCard> createState() => _PostCardState();
}
class _PostCardState extends State<PostCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: widget.imageUrl.isNotEmpty
                ? Image.network(
                    widget.imageUrl,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  )
                : const Icon(Icons.image_not_supported),
            title: Text(widget.title),
            subtitle: Text(widget.tagList),
          ),
        ],
      ),
    );
  }
}