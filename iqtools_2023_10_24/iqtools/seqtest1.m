function seqtest1()
% Demonstration of M8190A sequencing capabilities
% Output is best viewed on an oscilloscope.
% This demo contains three sections:
% - static sequence (i.e. a executing a pre-defined sequence)
% - dynamic sequence (i.e. switching sequence states at runtime)
% - memory ping pong (i.e. downloading new waveforms at runtime)
% Instrument Configuration has to be set up using IQtools config dialog
% before running this demo
%
% Thomas Dippon, Keysight Technologies 2011-2016
%
% Disclaimer of Warranties: THIS SOFTWARE HAS NOT COMPLETED KEYSIGHT'S FULL
% QUALITY ASSURANCE PROGRAM AND MAY HAVE ERRORS OR DEFECTS. KEYSIGHT MAKES 
% NO EXPRESS OR IMPLIED WARRANTY OF ANY KIND WITH RESPECT TO THE SOFTWARE,
% AND SPECIFICALLY DISCLAIMS THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
% FITNESS FOR A PARTICULAR PURPOSE.
% THIS SOFTWARE MAY ONLY BE USED IN CONJUNCTION WITH KEYSIGHT INSTRUMENTS. 


% make sure that we can connect to the M8190A and have the right licenses
if (~iqoptcheck([], 'bit', 'SEQ'))
    return;
end

% define the sample rate
fs = 8e9;
% define the segment length (make sure it divides evenly into 64 as well as
% 48, so that it can run in 12 bit as well as 14 bit mode
segLen = 3840;
% set up a couple of waveform segments
% single pulse
s1 = iqpulsegen('pw', segLen/2, 'off', segLen/2, 'rise', 0, 'fall', 0);
s1(segLen) = 0;
% noise
s2 = rand(segLen, 1) - 0.5;
s2(segLen) = 0;
% a triangle waveform
s3 = iqpulsegen('pw', 0, 'off', 0, 'rise', segLen/4, 'fall', segLen/4, 'high', [0.5 -0.5], 'low', 0);
% a sinusoidal waveform
s4 = 0.75*sin(2*pi*(1:segLen)/segLen);

% start from scratch and delete all segments
iqseq('delete', []);
% download the waveform segments - identical data on channel 1 and 2
% don't start waveform playback ('run', 0)
iqdownload(s1, fs, 'chMap', [1 0; 1 0], 'segmentNumber', 1, 'run', 0);
iqdownload(s2, fs, 'chMap', [1 0; 1 0], 'segmentNumber', 2, 'run', 0);
iqdownload(s3, fs, 'chMap', [1 0; 1 0], 'segmentNumber', 3, 'run', 0);
iqdownload(s4, fs, 'chMap', [1 0; 1 0], 'segmentNumber', 4, 'run', 0);

duration = 0.5;  % seconds
repeatCnt = round(duration * fs / segLen);
% and set up the sequence
advanceMode = 'Auto';       % replace 'Auto' with 'Conditional' to show
                            % how the sequencer can wait for an event.
                            % You can press the "Force Event" button
                            % or apply a signal to the Event input
                            % to trigger the event
clear seq;
for i = 1:4
    % set up each sequence entry - refer to iqseq.m for all possible fields
    seq(i).segmentNumber = i;
    seq(i).segmentLoops = repeatCnt;
    seq(i).markerEnable = true;
    seq(i).segmentAdvance = advanceMode;
end
iqseq('define', seq, 'chMap', [1 0; 1 0]);
iqseq('mode', 'STSC', 'chMap', [1 0; 1 0]);

hMsgBox = iqwaitbar('', 'Click "Cancel" to stop');
for i=1:50
    hMsgBox.update(i/50, 'Executing static sequence - observe scope');
    if (hMsgBox.canceling); break; end
    pause(0.5);
end
delete(hMsgBox);

% demonstrate dynamic switching between segments
iqseq('mode', 'ARB', 'chMap', [1 0; 1 0]);  % switch to ARB Mode
iqseq('dynamic', 1, 'chMap', [1 0; 1 0]);   % turn on dynamic mode
iqseq('mode', 'ARB', 'chMap', [1 0; 1 0]);  % run
hMsgBox = iqwaitbar('', 'Click "Cancel" to stop');
f = iqopen();
for i = 1:50
    % dynamically select segments - alternatively, use dynamic sequence
    % control connector
    segNum = floor(rand() * 4);
    hMsgBox.update(i/50, sprintf('Dynamic Select Segment #%d', segNum));
    if (hMsgBox.canceling); break; end
    xfprintf(f, sprintf(':stab:dyn:sel %d', segNum));
    pause(0.5);
end
delete(hMsgBox);

% demonstrate pingpong: re-load segments at runtime - note: segment length can not be changed
hMsgBox = iqwaitbar('', 'Click "Cancel" to stop');
pingpong = 1;
while pingpong < 50
    pause(0.5);
    hMsgBox.update(pingpong / 50, sprintf('Download Segment #%d ...', pingpong));
    if (hMsgBox.canceling()); break; end
    % create a signal
    sig = (0.2 + 0.8*rand(1))*sin(randi([1,12])*2*pi*(1:segLen)/segLen);
    % download to a segment that is currently not in use
    iqdownload(complex(real(sig), real(sig)), fs, 'segmentNumber', mod(pingpong,2)+1, 'keepOpen', 1, 'run', -1);
    pause(0.5);
    hMsgBox.update(pingpong / 50, sprintf('Select Segment #%d ...', pingpong));
    if (hMsgBox.canceling()); break; end
    % ...and select the associated sequence table entry
    xfprintf(f, sprintf(':stab:dyn:sel %d', mod(pingpong,2)));
    pingpong = pingpong + 1;
end
delete(hMsgBox);

iqclose(f);

% keep the following line the last line in the file
end
