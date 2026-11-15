# ZCU216 board interface

The 2026-11-15 board audit recovered the notebook and server modules in
[doa_rfsoc/PS/python/beamforming](https://github.com/Seguar/doa_rfsoc/tree/zcu216/PS/python/beamforming).
Use `VSA_rfsoc_new.mlapp` for this workflow. Its App Designer source and
`VSA_rfsoc_new_exported.m` include `stream N`, `dacbfcorr`, and
`dacbf tracking/retracking`; the older application lacks these controls.
No MATLAB application source changes were needed to recover these features.

## Connection and data contract

Set the board address in the application; default server port is **4000**.
The Jupyter UI port is independent. `Functions/rfsocConnect.m` still retains
its legacy USB/direct-address fallbacks, so check which board answered.

Requests end in a newline. `#` separates commands, `/` separates arguments.
The recovered server sends one frame for each nonempty request by default when
streaming is enabled. `stream N` requests N frames; `stream 0` suppresses data.
Drain every pending frame before changing acquisition parameters; the new app's
`streamFramesPending` accounting implements this.

The default selected RF channels are 0, 1, 2, 3. Each sample is packed as
`I0,Q0,I1,Q1,I2,Q2,I3,Q3`, **little-endian int16**, without a length header.
`data_size` counts int16 values, not bytes or complex samples. With 16384 complex
samples/channel and eight lanes, one frame is 131072 values / 262144 bytes.
`Functions/tcpDataRec.m` reconstructs each complex sample as `I - 1j*Q`.
Its `typecast` uses host endianness, consistent with the intended Windows host.

## Tracking and calibration

`dacbf off`, `dacbf tracking`, and `dacbf retracking` control notebook tracking.
`dacbfcorr` arguments are hundredths of a degree; the MATLAB controls multiply
their degree values by 100 before sending. `dacbfcorrdeg` accepts degrees directly.

Corrected MVDR uses board-local `steering_correction.mat` and
`pow_claibration_intrp.mat` (retain that spelling). Upload calibration for the
actual array into the notebook directory. These files were not collected in the
audit. The worker supports optional `algo_config.npz`/`.mat`; absent initial
configuration falls back to identity corrections, which is not calibrated
operation. The recovered notebook auto-reloads correction files when tracking
or retracking is requested. DAC waveform mode 4 additionally needs board-local
`data.mat` with `sigInt16`.

## Evidence and limits

The selected notebook had saved configuration/import/overlay-setup execution
counts, but no saved serving-cell count. Board clock and root-history access
limitations prevent proof of the latest live session. Source inspection confirms
the client/server framing and command conventions; no end-to-end MATLAB session,
RF output, beam pattern, or tracking accuracy was tested in this reconciliation.
