%
% Kandou mapping from data to wire levels (scaled from 0 to 1)
% data can be 'Random', 'PRBS 2^N-1' or a vector of bits
% numSymbols is the number of symbols to be generated
% numSymbols can be set to zero in case of PRBS
% type can be 'CNRZ5' or 'ENRZ'
%
function result = iqkandoupattern(data, numSymbols, type, levels)
%
cnrz5code = ([...
-2	7	4	-2	1	-8; ...
-8	1	-2	4	7	-2; ...
2	-1	8	-2	1	-8; ...
-4	-7	2	4	7	-2; ...
4	7	-2	-2	1	-8; ...
-2	1	-8	4	7	-2; ...
8	-1	2	-2	1	-8; ...
2	-7	-4	4	7	-2; ...
-2	7	4	2	-7	-4; ...
-8	1	-2	8	-1	2; ...
2	-1	8	2	-7	-4; ...
-4	-7	2	8	-1	2; ...
4	7	-2	2	-7	-4; ...
-2	1	-8	8	-1	2; ...
8	-1	2	2	-7	-4; ...
2	-7	-4	8	-1	2; ...
-2	7	4	-8	1	-2; ...
-8	1	-2	-2	7	4; ...
2	-1	8	-8	1	-2; ...
-4	-7	2	-2	7	4; ...
4	7	-2	-8	1	-2; ...
-2	1	-8	-2	7	4; ...
8	-1	2	-8	1	-2; ...
2	-7	-4	-2	7	4; ...
-2	7	4	-4	-7	2; ...
-8	1	-2	2	-1	8; ...
2	-1	8	-4	-7	2; ...
-4	-7	2	2	-1	8; ...
4	7	-2	-4	-7	2; ...
-2	1	-8	2	-1	8; ...
8	-1	2	-4	-7	2; ...
2	-7	-4	2	-1	8; ...
]);
% ENRZ (columns are reversed)
enrzcode = fliplr([...
-3	 1	 1	 1; ...
-1	-1	 3	-1; ...
-1	-1	-1	 3; ...
 1	-3	 1	 1; ...
-1	 3	-1	-1; ...
 1	 1	 1	-3; ...
 1	 1	-3	 1; ...
 3	-1	-1	-1; ...
]);

if (strcmp(type, 'CNRZ5'))
    striping = 5;
    code = cnrz5code;
elseif (strcmp(type, 'ENRZ'))
    striping = 3;
    code = enrzcode;
elseif (strcmp(type, 'DuoBinary'))
    striping = 3;
    code = [];
elseif (strcmp(type, 'clock'))  % no encoding in case of clock
    result = data;
    return;
else
    error('unexpected type');
end
mincode = min(min(code));
maxcode = max(max(code));
randStream = RandStream('mt19937ar'); 
reset(randStream);

if (ischar(data))
    prbsPoly = [];
    switch(upper(data))
        case 'RANDOM'
            if (numSymbols == 0)
                error('for random data, numSymbols must be specified');
            end
            data = randStream.randi([0 1], 1, numSymbols * striping);
        case 'COUNTER'
            if (numSymbols == 0)
                error('for counter pattern, numSymbols must be specified');
            end
            m = 2^striping;
            data = repmat(dec2bin(0:m-1), ceil(numSymbols/m), 1)';
            data = double(data(1:numSymbols*striping)-48);
        case 'PRBS2^7-1'
            prbsPoly = [7 1 0];
        case 'PRBS2^9-1'
            prbsPoly = [9 4 0];
        case 'PRBS2^10-1'
            prbsPoly = [10 3 0];
        case 'PRBS2^11-1'
            prbsPoly = [11 2 0];
        case 'PRBS2^12-1'
            prbsPoly = [12 11 8 6 0]; % alternative [12 6 4 1 0]
    %    case 'PRBS2^12-1'
    %        prbsPoly = [12 6 4 1 0]; % alternative [12 11 8 6 0]
        case 'PRBS2^13-1'
            prbsPoly = [13 12 11 1 0];
        case 'PRBS2^15-1'
            prbsPoly = [15 1 0];
        otherwise
            error('unexpected data type');
    end
    if (~isempty(prbsPoly))
        if (numSymbols == 0)
            numSymbols = 2^prbsPoly(1) - 1;
        end
          h = comm.PNSequence('Polynomial', prbsPoly, 'SamplesPerFrame', numSymbols * striping, 'InitialConditions', [zeros(1,prbsPoly(1)-1), 1]);
          data = h.step()';
%         h = commsrc.pn('GenPoly', prbsPoly, 'NumBitsOut', numSymbols * striping);
%         data = h.generate()';
    end
end
len = length(data);
if (mod(len, striping) ~= 0)
    errordlg(sprintf('pattern length must be a multiple of %d bits', striping));
end
% DuoBinary does not have a code table
if (isempty(code))
    % convert from 0/1 to -1/1
    data = data * 2 - 1;
    % reshape to 3 bits per row
    data = reshape(data, striping, len/striping);
    % prepend the last symbol to the beginning so we can build differences
    abc = [data(:,end) data];
    suw = diff(abc,1,2)/2;
    w(:,1) =  suw(1,:) + suw(2,:) + suw(3,:);
    w(:,2) = -suw(1,:) + suw(2,:) - suw(3,:);
    w(:,3) =  suw(1,:) - suw(2,:) - suw(3,:);
    w(:,4) = -suw(1,:) - suw(2,:) + suw(3,:);
    mincode = -3;
    maxcode = 3;
else
% calculate values based on coding table (ENRZ or CNRZ5)
    data = reshape(data, striping, len/striping)';
    w = zeros(size(data,1), size(code,2));
    for i = 1:size(data,1)
        x = bin2dec(char(fliplr(data(i,:)) + 48));
        w(i,:) = code(x+1,:);
    end
end

% check correct encoding
checkCoding = 0;
if (checkCoding)
    if (striping == 5)
        data2 = [(w(:,6)+w(:,5)+w(:,4)-w(:,3)-w(:,2)-w(:,1))/3, ...
              (w(:,1)+w(:,3))/2-w(:,2), ...
              (w(:,1)-w(:,3)), ...
              (w(:,6)+w(:,4))/2-w(:,5), ...
              (w(:,6)-w(:,4))] / 12 + 0.5;
    else
        data2 = [w(:,4)-w(:,3)+w(:,2)-w(:,1), ...
              w(:,4)-w(:,3)-w(:,2)+w(:,1), ...
              w(:,4)+w(:,3)-w(:,2)-w(:,1)] / 8 + 0.5;
    end
    if (~isequal(data2, data))
        disp(data);
        disp(data2);
        error('data decode error');
    end
end
if (~exist('levels', 'var') || isempty(levels))
    % if no levels specified, scale to 0...1
    w = (w - mincode) / (maxcode - mincode);
else
    % scale to 0...(number of levels)-1 and index into level values
    w = round((w - mincode) * (length(levels) - 1) / (maxcode - mincode));
    w = levels(w+1);
end
result = w;
