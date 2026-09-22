/// Returns a rune-safe presentation monogram. Only the initial is converted
/// from full-width printable Latin/ASCII to ASCII; the team name is untouched.
String teamInitial(String displayName) {
  if (displayName.runes.isEmpty) return '?';
  final initial = displayName.runes.first;
  final ascii = initial >= 0xff01 && initial <= 0xff5e
      ? initial - 0xfee0
      : initial;
  return String.fromCharCode(ascii);
}
