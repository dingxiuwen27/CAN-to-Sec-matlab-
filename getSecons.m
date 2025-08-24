function SEC = getSecons(strFile)
% Detect import options with proper delimiter
opts = detectImportOptions(strFile, 'Delimiter', ',', 'NumHeaderLines', 1);

% Read numeric data using readmatrix
SEC.rawData = readmatrix(strFile, opts);

% Open file and manually extract header line
fid = fopen(strFile, 'r');
headerLine = fgetl(fid); % Read first line (header)
fclose(fid);

% Process header: Remove quotes and split correctly
headerCleaned = regexprep(headerLine, '"', ''); % Remove extra quotes
SEC.strHeader = regexp(headerCleaned, ',', 'split'); % Convert to cell array

% Remove potential empty first column if necessary
if all(isnan(SEC.rawData(:, 1)))
    SEC.rawData(:, 1) = [];
    SEC.strHeader(1) = []; % Remove corresponding header
end

% Identify dynamic signals (columns that change over time)
SEC.dynSignals = any(diff(SEC.rawData) ~= 0, 1);

% Process each column to detect binary status flags
numCols = size(SEC.rawData, 2);
SEC.isStatus = false(1, numCols);
SEC.numStatusBitFlips = zeros(1, numCols);
SEC.rStBitOnTime = zeros(1, numCols);

for n = 1:numCols
    uniqueVals = unique(SEC.rawData(:, n));
    SEC.isStatus(n) = numel(uniqueVals) == 2; % Binary check

    if SEC.isStatus(n)
        % Count bit flips
        SEC.numStatusBitFlips(n) = sum(diff(SEC.rawData(:, n)) ~= 0);

        % Compute on-time percentage (normalized)
        minVal = min(SEC.rawData(:, n));
        maxVal = max(SEC.rawData(:, n));
        if maxVal > minVal
            normSignal = (SEC.rawData(:, n) - minVal) / (maxVal - minVal);
            SEC.rStBitOnTime(n) = trapz(SEC.rawData(:, 1), normSignal) / ...
                (SEC.rawData(end, 1) - SEC.rawData(1, 1));
        else
            SEC.rStBitOnTime(n) = 0;
        end
    end

    % Display status signals
    if SEC.isStatus(n)
        fprintf('%s: Column %d | Bit Flips: %d | On Time: %.1f%%\n', ...
            SEC.strHeader{n}, n, SEC.numStatusBitFlips(n), 100 * SEC.rStBitOnTime(n));
    end
end


SEC.nrmData(:,1) = SEC.rawData(:,1);

for n = 2:width(SEC.rawData);
    maxData = max(SEC.rawData(:,n));
    minData = min(SEC.rawData(:,n));
    if maxData > minData
        SEC.nrmData(:,n) = (SEC.rawData(:,n) - minData) / (maxData - minData);
    else
        SEC.nrmData(:,n) = zeros(size(SEC.rawData(:,n)));
    end
end

SEC.ti= SEC.rawData(:,1);
SEC.rawData = SEC.rawData(:,2:end);
SEC.nrmData = SEC.nrmData(:,2:end);