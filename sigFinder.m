function [sig, fb_lines, fe_lines, f_len, f_wid] = sigFinder(sigRec, findCoef, minLen)
    findTrh = mean(abs(sigRec))*findCoef;
    cutInd = abs(sigRec) >= findTrh;
    buff(cutInd) = 1;
    gap = 1;
    pack = 1;
    sig = [];
    for i = 1:length(buff)
        if (buff(i) == 0)
          gap = gap + 1;  
        else
            if gap > minLen
                sig(pack,:) = [i,gap];
                gap = 0;
                pack = pack + 1;
            else
                gap = 0;
            end
        end
    end

    sig(pack,:) = [i,gap]; % Last part
    f_wid = median(sig(:,2));
    fb_lines = sig(:,1);
    fe_lines = sig(2:end,1) - sig(2:end,2); % Works on any lengths
    fe_lines = fe_lines(fe_lines > 0);
    fb_lines = fb_lines(1:length(fe_lines));
    f_len = median(fe_lines - fb_lines);
    if fe_lines < fb_lines
        fe_lines = fe_lines(2:end);
        fe_lines(end) = fb_lines(end);
        fb_lines = fb_lines(1:end-1);
    end
if not(isempty(fe_lines))
    if fe_lines(end)-fb_lines(end) < f_len
        fb_lines = fb_lines(1:end-1);
        fe_lines = fe_lines(1:end-1);
    end
end