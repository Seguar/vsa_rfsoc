function M = M_k(k)

if (sum(k == 0:4) > 0)
    M = k - 26;
elseif (sum(k == 5:17) > 0)
    M = k - 25;
elseif (sum(k == 18:23) > 0)
    M = k - 24;
elseif (sum(k == 24:29) > 0)
    M = k - 23;
elseif (sum(k == 30:42) > 0)
    M = k - 22;
elseif (sum(k == 43:47) > 0)
    M = k - 21;
end
   
end