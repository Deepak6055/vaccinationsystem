String chatIdFor(String a, String b) {
  // deterministic id for 1:1 chat
  final u = [a, b]..sort();
  return '${u[0]}_${u[1]}';
}
