function [p_manual_mean_db, p_manual_mean]  = avgData(p_manual, p_manual_mean)
    p_manual_mean(:,1:end-1) = p_manual_mean(:,2:end);
    p_manual_mean(:,end) = p_manual;
    p_manual_mean_vec = mean(p_manual_mean, 2);
    p_manual_mean_db = 20*log10(p_manual_mean_vec);
    p_manual_mean_db = p_manual_mean_db - max(p_manual_mean_db);    
