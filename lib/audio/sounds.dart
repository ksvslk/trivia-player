List<String> soundTypeToFilename(SfxType type) {
  switch (type) {
    case SfxType.send:
      return const ['send.wav'];
    case SfxType.bell:
      return const ['bell.wav'];
    case SfxType.correct:
      return const ['correct.wav'];
    case SfxType.roundEnd:
      return const ['roundEnd.wav'];
  }
}

enum SfxType {
  send,
  bell,
  correct,
  roundEnd
}
