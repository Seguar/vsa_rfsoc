# RFSoC 4x2 board interface — 2026-11-15 audit

Recovered board code and provenance are in
[doa_rfsoc main](https://github.com/Seguar/doa_rfsoc/tree/main/runtime/rfsoc4x2).
The observed live process is `/boot/boot.py`. The newer saved `MultiTest`
notebooks contain alternative experiments; their active-session status is unknown.

The boot server accepts TCP on port 4000. Requests end in CR or LF, `#` separates
commands and `/` separates integer arguments. Raw samples are native int16 on
the little-endian board, with eight I/Q lanes for four complex channels. Default
frame size is 131072 values / 262144 bytes; `dataChan` changes it. The existing
`Functions/tcpDataRec.m` uses the corresponding `I - 1j*Q` convention.

**The boot server streams continuously after a command while dataStream is true.**
It does not service commands inside that loop. Consequently a later stop command
can remain unread, and one MATLAB request does not imply one frame. This differs
from the bounded burst accounting in `VSA_rfsoc_new.mlapp` for the ZCU216 server.
Do not enable `stream N` or notebook `dacbf` controls against this recovered 4x2
wrapper. No existing MATLAB app is claimed fully compatible from source recovery
alone; live frame accounting and control behavior remain to be tested.

`MultiTest/main.ipynb` is another continuous TCP experiment with placeholder
control reception. `newProto.ipynb` experiments with JSON control over TCP and
samples over UDP; it cannot use the existing raw TCP reader unchanged. These
notebooks were preserved, not promoted to supported server replacements.

Set the target board address explicitly. The shared connection helper has legacy
USB/direct fallback addresses, which can connect to a different board when
multiple RFSoC boards are present. Verify identity before hardware operations.
The audit verified file hashes and static protocol structure, not end-to-end
MATLAB acquisition, RF performance or beamforming accuracy.
