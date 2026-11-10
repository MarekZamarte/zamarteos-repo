# Fairphone 4 hardware status

## Verified in the upstream Moarchy FP4 development tree

The upstream device notes report a real Fairphone 4 test on 2026-10-17:
an incoming call was answered and audio was heard in both directions on a
hand-built Linux 7.2.0-voice kernel. The same notes say that the packaged CI
image still needed a repeat call test. This distinction is retained here:
the hand-built kernel report is evidence, not proof that our image is ready.

The tested voice PCM list was:
- 00-02: CS-VOICE
- 00-03: VoiceMMode1

The FP4 q6voiced configuration selects card 0, device 3 (VoiceMMode1).

## Remaining risks
- an audio-related boot race;
- Wi-Fi latency/stability work;
- occasional EDL recovery incidents;
- VoLTE/IMS behaviour depends on the operator and network.

No Plus-specific VoLTE test is claimed. Q6Voice enables the Linux-side audio
path; it does not by itself guarantee IMS registration or VoLTE on Plus.

## Sources
- https://github.com/taufderl/moarchy/blob/fp4/docs/fp4-defects.md
- https://github.com/taufderl/moarchy/blob/fp4/docs/fairphone-4.md
- https://github.com/taufderl/moarchy/blob/fp4/pkgbuilds/moarchy-device-fp4/q6voiced.conf

## Flash policy
Do not flash the reference build. First obtain a successful build, inspect the
artifact and verify its boot/partition assumptions. Then develop and test the
ZamarteOS shell separately. Flashing is a later, explicit step.
