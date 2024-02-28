function [p_manual_mean_vec, dataMean]  = avgData(data, dataMean)
    dataMean(:,1:end-1) = dataMean(:,2:end);
    dataMean(:,end) = data;
    p_manual_mean_vec = mean(dataMean, 2);
    
