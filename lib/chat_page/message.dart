class Message {
  final String text;
  final String badgeText;
  final bool isBot;
  final int timestamp;
  final String name;
  final int roundNumber;
  final String id;
  final String messageType;
  final String playerUid;
  final int questionStartTime;
  final int questionEndTime;
  final int serverTime;

  Message(
      {required this.text,
      required this.badgeText,
      required this.isBot,
      required this.timestamp,
      required this.name,
      required this.roundNumber,
      required this.id,
      required this.messageType,
      required this.playerUid,
      required this.questionStartTime,
      required this.questionEndTime,
      required this.serverTime});
}
