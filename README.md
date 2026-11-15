Applications for RFSoC communication and DOA with beamforming.

**VSA_rfsoc.mlapp** - original application

**ZCU216 notebook beamforming:** use **VSA_rfsoc_new.mlapp** with the
[recovered board server](https://github.com/Seguar/doa_rfsoc/tree/zcu216/PS/python/beamforming).
Both this App Designer file and its exported MATLAB source contain burst-stream
and notebook DAC-tracking controls; the older `VSA_rfsoc.mlapp` does not.
See [the board interface notes](docs/zcu216-board-interface.md) for frame layout,
calibration inputs, and the limits of the 2026-11-15 reconciliation.

**Requirements:**

Matlab 2024b+ + [Instrument Control Toolbox Support Package for Keysight IO Libraries and VISA Interface](https://www.mathworks.com/matlabcentral/fileexchange/52245-instrument-control-toolbox-support-package-for-keysight-io-libraries-and-visa-interface)

VSA 89600 v.2022U1+ with [DDC](https://www.keysight.com/zz/en/assets/3121-1464/application-notes/VSA-89600-Direct-Data-Connectivity.pdf) license

Ethernet/USB connection with board and SDRs/VSGs



**IQtools:**
https://www.keysight.com/zz/en/lib/software-detail/computer-software/keysight-iqtools.html
