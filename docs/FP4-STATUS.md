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

## Call-audio acceptance in the ZamarteOS image

The pinned hardware base used by the Pure FP4 builder includes
`0009-call-audio-q6voice.patch` in `linux-moarchy-sm6350` (pkgrel 13),
the Q6Voice kernel modules, FP4 voice DAIs, `q6voiced`, and the measured
`VoiceMMode1` selection (card 0, device 3). It also builds and enables the
`81voltd` IMS data service for VoLTE-only networks, and carries the FP4 UCM,
WirePlumber settings, and mixer-route helper for the call uplink/downlink.

The ZamarteOS image verifier now treats these as required image contents:
missing Q6Voice modules, daemon/config, UCM files, or call mixer routes fail
the image audit. This is a packaging gate, not an acoustic test.

**Release gate still outstanding:** on the actual FP4, place and receive calls
and confirm two-way audio through the earpiece and loudspeaker, microphone
uplink, and call-progress/ringback tone. The upstream hand-built kernel report
is evidence that this path can work on FP4; it does not prove that this exact
CI image works. No modem configuration is changed as part of this audio work.

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
