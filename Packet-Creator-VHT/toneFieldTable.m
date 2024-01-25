function N_tone_field = toneFieldTable(field, BW_channel)

switch field
    case {'L-STF', 'VHT-STF'}
        if BW_channel == 20
            N_tone_field = 12;
        elseif BW_channel == 40
            N_tone_field = 24;
        elseif BW_channel == 80
            N_tone_field = 48;
        elseif BW_channel == 160
            N_tone_field = 96;
        end;
        
    case {'L-LTF', 'L-SIG', 'VHT-SIG-A'}
        if BW_channel == 20
            N_tone_field = 52;
        elseif BW_channel == 40
            N_tone_field = 104;
        elseif BW_channel == 80
            N_tone_field = 208;
        elseif BW_channel == 160
            N_tone_field = 416;
        end;
        
    case {'VHT-LTF', 'VHT-SIG-B', 'Data'}
        if BW_channel == 20
            N_tone_field = 56;
        elseif BW_channel == 40
            N_tone_field = 114;
        elseif BW_channel == 80
            N_tone_field = 242;
        elseif BW_channel == 160
            N_tone_field = 484;
        end;
end;