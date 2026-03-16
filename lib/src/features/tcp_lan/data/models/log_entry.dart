class LogEntry {
  final String text;
  final bool isSystem;
  final bool isMine;
  LogEntry(this.text, {this.isSystem = false, this.isMine = false});
}
