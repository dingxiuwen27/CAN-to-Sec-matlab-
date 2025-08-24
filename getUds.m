function UdsData = getUds(strFileCan)
    % Read and process CAN log file
    rawData = readmatrix(strFileCan);
    rawData(end, :) = [];  % Remove last empty row if exists

    % Extract relevant columns
    numAllIds = rawData(:, 2);   % CAN Identifiers
    numD0 = rawData(:, 4);     % PCA data (D0)
    numTime = rawData(:, 12);    % Timestamp

    % Detect relevant gateway IDs using specific PCI bytes
    relevantIds = numAllIds(numD0 == 16 | numD0 == 33 );

    % Determine most frequent gateway ID
    [uniqueIds, ~, counts] = unique(relevantIds);
    idCounts = accumarray(counts, 1);
    [maxCount, maxIdx] = max(idCounts);

    % Check if the ID is dominant (90% threshold)
    if maxCount > 0.9 * numel(relevantIds)
        numIdGtwy = uniqueIds(maxIdx);
        fprintf('Detected Gateway ID: %d\n', numIdGtwy);
    else
        disp('No definitive Gateway ID determined.');
        return;
    end

    % Filter only messages with the detected Gateway ID
    response_idx = (numAllIds == numIdGtwy);
    response_data = rawData(response_idx, 4:11);  % Data bytes (D0 - D7)
    response_times = numTime(response_idx);

    % ISO-TP Reassembly
    UdsData = struct('ti', {}, 'numId', {}, 'bytes', {});
    messageBuffer = [];  % Stores concatenated messages
    expectedSN = 1;      % Expected sequence number
    total_size = 0;      % Total expected size of message
    firstFrameTime = 0;  % Store timestamp of first frame

    for i = 1:size(response_data, 1)
        frame = response_data(i, :);
        pci_byte = frame(1);
        frame_type = bitshift(pci_byte, -4);  % First 4 bits indicate frame type

        switch frame_type
            case 0 % Single Frame (SF)
                payload_size = bitand(pci_byte, 0x0f); % Last 4 bits indicate payload size
                UdsData(end+1).ti = response_times(i);
                UdsData(end).numId = numIdGtwy;
                UdsData(end).bytes = frame(2:1+payload_size);

                % Display message
                %disp(sprintf('time: %0.1f | ID: %0.0f | bytes: %s', ...
               %     UdsData(end).ti, UdsData(end).numId, sprintf('%0.0f ', UdsData(end).bytes)));

            case 1 % First Frame (FF)
                total_size = bitand(pci_byte, 15) * 256 + frame(2);
                messageBuffer = frame(3:8); % First payload segment
                expectedSN = 1; % Reset sequence number tracking
                firstFrameTime = response_times(i); % Store timestamp of FF

            case 2 % Consecutive Frame (CF)
                seq_num = bitand(pci_byte, 15);
                if seq_num == expectedSN % Check sequence number
                    messageBuffer = [messageBuffer, frame(2:8)]; % Append data
                    expectedSN = mod(expectedSN + 1, 16); % Wrap around at 0xF

                    % If message is complete, store and reset buffer
                    if length(messageBuffer) >= total_size
                        UdsData(end+1).ti = firstFrameTime;
                        UdsData(end).numId = numIdGtwy;
                        UdsData(end).bytes = messageBuffer(1:total_size);

                        % Display message
                     %   disp(sprintf('time: %0.1f | ID: %0.0f | bytes: %s', ...
                      %      UdsData(end).ti, UdsData(end).numId, sprintf('%0.0f ', UdsData(end).bytes)));

                        messageBuffer = [];
                    end
                end
        end
    end
end