close all,  clear, clc
%set Variables
strPath = 'C:\Masterarbeit\nexo\Messwerte\03112025\';
strEcu = 'HDC';
stPltGraph =1;
dtiOfs =4.3 ;% HDC = 4.3 | LDC = 5.1 | MCU2 = 14.4 FCU=6.4 BMS=10.824 HSCU=5.114
rErrThres = 10; % error threshold

% Load UDS data and process
UDS = getUds([strPath 'CanKing_' strEcu '.txt']);
DID = getDidFromUds(UDS);
% Load secondary data
SEC = getSecons([strPath 'Secons_' strEcu '.csv']);
SEC.strHeader([1, end]) = []; % Remove first and last headers
% Setup for offset adjustment
dti = zeros(size(DID)) + dtiOfs;
% Initialize results table
IdHeader=(1:length(SEC.strHeader))';
resultTable = table(IdHeader, SEC.strHeader', 'VariableNames', {'Signal Idx','SignalName'});
resultTable.Dynamic = zeros(height(resultTable), 1); % Column for Dynamic flag
countMatch = 0;
MatchData = cell(1, length(SEC.strHeader));

% Iterate over each DID
for i = 1:length(DID)
    % Process each DID
    VAL = getByteStream(DID(i));

    for numBit = 1:16
        VAL(numBit).arrayVal(VAL(numBit).ti>VAL(numBit).ti(end)-dti(i),:) = [];
        VAL(numBit).arrayValNrm(VAL(numBit).ti>VAL(numBit).ti(end)-dti(i),:) = [];
        VAL(numBit).ti(VAL(numBit).ti>VAL(numBit).ti(end)-dti(i)) = [];
    end

    % Initialize columns for this DID
    resultTable.(['Numbit_DID' num2str(i)]) = NaN(height(resultTable), 1);
    resultTable.(['IdxStart_DID' num2str(i)]) = NaN(height(resultTable), 1);
    resultTable.(['MinErr_DID' num2str(i)]) = NaN(height(resultTable), 1);
    % Initialize Scale and Offset columns for this DID
    resultTable.(['Scale_DID' num2str(i)]) = NaN(height(resultTable), 1);
    resultTable.(['Offset_DID' num2str(i)]) = NaN(height(resultTable), 1);

    % Prepare visualization for each DID
    figMaster = figure(100000 + i);
    set(figMaster, 'Name', sprintf('Master DID %d', i))
    hdl2 = subplot(1, 1, 1);
    drawBaseTable(hdl2, width(DID(i).arrayByte));
    % if i==1 drawBaseTable(hdl1, width(DID(i).arrayByte));
    % end
    countDyn = 0;
    numCols = size(SEC.nrmData, 2); % Get the actual number of data columns
    numHeaders = length(SEC.strHeader); % Get the number of headers
    validCols = min(numHeaders, numCols); % Ensure valid iteration range

    % Iterate over specified headers
    for n =1:validCols
        RES(n).strLab = SEC.strHeader{n};

        % Ensure n does not exceed available columns in SEC.nrmData
        if n > numCols
            warning('Skipping index %d as it exceeds data column size', n);
            continue;
        end

        % Check if the signal is static
        isStatic = all(diff(SEC.nrmData(:, n)) == 0); % Safe indexing
        RES(n).dyn = ~isStatic;

        if isStatic
            continue;
        end

        countDyn = countDyn + 1;

        for numBit = 1:16
            valNrmRef = interp1(SEC.ti - dti(i), SEC.nrmData(:, n), VAL(numBit).ti)';
            err = 100 * mean(abs(VAL(numBit).arrayValNrm - valNrmRef));
            RES(n).mse{numBit} = err;
            [minErr, idxMinErr] = min(err);
            RES(n).minErr(numBit) = minErr;
            RES(n).idxMnErr(numBit) = idxMinErr;


            SECrawdata=SEC.rawData(:,n);
            CANrawdata=VAL(numBit).arrayVal(:,idxMinErr);

            % Find the minimum length of both arrays
            minLength = min(length(SECrawdata), length(CANrawdata));

            % Truncate both arrays to the same length
            SECrawdata = SECrawdata(1:minLength);
            CANrawdata = CANrawdata(1:minLength);
            x = CANrawdata(:);
            y = SECrawdata(:);

            % Only fit if x has enough variation
            if range(x) < 1e-6 || all(isnan(x)) || all(isnan(y))
                scale = NaN;
                offset = NaN;
                disp('Skipping polyfit due to constant or invalid CAN data');
            else
                % Center x and y to improve numerical stability
                xCentered = x - mean(x);
                yCentered = y - mean(y);

                % Fit centered data
                pCentered = polyfit(xCentered, yCentered, 1);

                % Recover original scale and offset
                scale = pCentered(1);
                offset = mean(y) - scale * mean(x);
            end


            convertedCANdata = scale * CANrawdata + offset;

            % Visualization of results
            if stPltGraph
                figResult = figure(1000000 + n + i * 1000);
                set(figResult, 'Name', RES(n).strLab, 'Position', [100, 100, 1000, 800]);
                subplot(4, 4, numBit);
                hold on;
                grid on;
                plot(VAL(numBit).ti, VAL(numBit).arrayValNrm(:, idxMinErr), 'k');
                plot(VAL(numBit).ti, valNrmRef, 'g');
                if minErr < rErrThres
                    title(sprintf('L:%0.0f|id:%0.0f|Err:%0.1f|Sc:%0.1f|Off:%0.1f', numBit, idxMinErr, minErr,scale, offset));
                else 
                    title(sprintf('L:%0.0f|id:%0.0f|Err:%0.1f', numBit, idxMinErr, minErr));
                end
            end
        end

        [RES(n).absMin, numBitMin] = min(RES(n).minErr);
        RES(n).idxAbsMin = RES(n).idxMnErr(numBitMin);
        % Update results table
        resultTable.Dynamic(n) = RES(n).dyn;
        resultTable.(['Numbit_DID' num2str(i)])(n) = numBitMin;
        resultTable.(['IdxStart_DID' num2str(i)])(n) = RES(n).idxAbsMin;
        resultTable.(['MinErr_DID' num2str(i)])(n) = RES(n).absMin;
       


        if minErr < rErrThres
            countMatch = countMatch + 1;
            randcol = rand(1,3);
            highlightTableCells(hdl2, width(DID(i).arrayByte), RES(n).idxAbsMin, numBitMin, randcol, n, minErr);

            % Store scale and offset in the results table
            resultTable.(['Scale_DID' num2str(i)])(n) = scale;
            resultTable.(['Offset_DID' num2str(i)])(n) = offset;

        end

    end
    fprintf('DID %d : %d\n',i, DID(i).numDid);
end
%% Write the table to Excel
writetable(resultTable, 'Result.xlsx', 'Sheet', strEcu, 'WriteMode', 'overwrite');
fprintf('total labels: %d | dynamic: %d | identified: %d\n',length(SEC.strHeader),countDyn,countMatch);