function slope = winEdge(Pad_Rate)
if (Pad_Rate == 0)
    slope = 0.5;
else
    slope = 0+1/(Pad_Rate + 2):1/(Pad_Rate + 2):1-1/(Pad_Rate + 2);     
end

