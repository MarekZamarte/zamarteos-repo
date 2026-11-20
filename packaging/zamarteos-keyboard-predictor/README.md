# Offline Polish word suggestions

This component is injected into the pinned moarchy-keyboard source during the
FP4 image build. It uses Hunspell's Polish dictionary locally; no text is sent
to a network service.

The first implementation is deliberately conservative: it offers up to three
corrections for a misspelled word after at least three characters. It does not
silently replace text, and it is disabled for password/PIN fields and terminal,
numeric and phone layouts. Selecting a suggestion replaces only the partial
word typed through the on-screen keyboard.

This is spelling correction, not yet context-aware next-word prediction. A
later stage needs a licensed Polish frequency list and n-gram data, plus tests
for inflection and word-context ranking. The UI must not claim next-word
prediction until those tests pass.

Dictionary runtime packages: `hunspell` and `hunspell-pl` (Arch Linux ARM
Extra). If the dictionary is absent, the keyboard continues to type normally
and simply hides the suggestion strip.
