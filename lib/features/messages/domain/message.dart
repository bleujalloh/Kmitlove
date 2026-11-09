import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.fromUid,
    required this.text,
    required this.createdAt,
    required this.readBy,
  });

  final String id;
  final String fromUid;
  final String text;
  final DateTime? createdAt;
  final List<String> readBy;

  factory ChatMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final ts = data['createdAt'] as Timestamp?;
    return ChatMessage(
      id: doc.id,
      fromUid: data['fromUid'] as String,
      text: data['text'] as String,
      createdAt: ts?.toDate(),
      readBy: List<String>.from(data['readBy'] as List? ?? []),
    );
  }
}

class MatchSummary {
  const MatchSummary({
    required this.matchId,
    required this.otherUid,
    required this.otherDisplayName,
    required this.lastMessagePreview,
    required this.lastMessageAt,
  });

  final String matchId;
  final String otherUid;
  final String otherDisplayName;
  final String? lastMessagePreview;
  final DateTime? lastMessageAt;
}
