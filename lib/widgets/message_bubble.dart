import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// A MessageBubble for showing a single chat message on the ChatScreen.
class MessageBubble extends StatelessWidget {
  // Create a message bubble which is meant to be the first in the sequence.
  const MessageBubble.first({
    super.key,
    required this.userImage,
    required this.username,
    required this.message,
    required this.imageUrl,
    required this.isMe,
    required this.timestamp,
  }) : isFirstInSequence = true;

  // Create a message bubble that continues the sequence.
  const MessageBubble.next({
    super.key,
    required this.message,
    this.imageUrl,
    required this.isMe,
    required this.timestamp,
  })  : isFirstInSequence = false,
        userImage = null,
        username = null;

  final bool isFirstInSequence;
  final String? userImage;
  final String? username;
  final String message;
  final bool isMe;
  final Timestamp timestamp;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeString = DateFormat('hh:mm a').format(timestamp.toDate());
    final isImageMessage = imageUrl != null && imageUrl!.isNotEmpty;

    return Stack(
      children: [
        if (userImage != null)
          Positioned(
            top: 15,
            right: isMe ? 0 : null,
            child: CircleAvatar(
              backgroundImage: NetworkImage(userImage!),
              backgroundColor: theme.colorScheme.primary.withAlpha(180),
              radius: 23,
            ),
          ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 46),
          child: Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (isFirstInSequence) const SizedBox(height: 18),
                  if (username != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 13, right: 13),
                      child: Text(
                        username!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      color: isImageMessage
                          ? Colors.transparent
                          : (isMe
                              ? Colors.grey[300]
                              : theme.colorScheme.secondary.withAlpha(200)),
                      borderRadius: BorderRadius.only(
                        topLeft: !isMe && isFirstInSequence
                            ? Radius.zero
                            : const Radius.circular(12),
                        topRight: isMe && isFirstInSequence
                            ? Radius.zero
                            : const Radius.circular(12),
                        bottomLeft: const Radius.circular(12),
                        bottomRight: const Radius.circular(12),
                      ),
                    ),
                    constraints: isImageMessage
                        ? BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.56,
                          )
                        : const BoxConstraints(maxWidth: 200),
                    padding: isImageMessage
                        ? EdgeInsets.zero
                        : const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 14,
                          ),
                    margin: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 12,
                    ),
                    child: isImageMessage
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  imageUrl!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Container(
                                alignment: Alignment.bottomRight,
                                child: Text(
                                  timeString,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isMe
                                        ? Colors.white
                                        : theme.colorScheme.onSecondary
                                            .withAlpha(150),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message,
                                style: TextStyle(
                                  height: 1.3,
                                  color: isMe
                                      ? Colors.black87
                                      : theme.colorScheme.onSecondary,
                                ),
                                softWrap: true,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                timeString,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isMe
                                      ? Colors.black54
                                      : theme.colorScheme.onSecondary
                                          .withAlpha(150),
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}