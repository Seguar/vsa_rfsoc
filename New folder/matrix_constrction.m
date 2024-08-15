% matrix construction
ang_scan = -60:10:60;
for k=1:length(ang_scan)
    if ang_scan(k) < 0
        sig_temp = load(strcat('m', num2str(ang_scan(k)*-1), '.mat'));
    else
        sig_temp = load(strcat(num2str(ang_scan(k)), '.mat'));
    end
    sig = sig_temp.saveFile.raw;  
    meas_mat(:,:,k) = sig;
end