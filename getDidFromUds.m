function StructDid = getDidFromUds(Uds)
    % Initialize UDS structure
    StructDid = struct('numDid', {}, 'ti', {}, 'arrayByte', {});

    % Temporary storage for sorting
    didMap = containers.Map('KeyType', 'double', 'ValueType', 'any');

    for i = 1:length(Uds)
        % Extract UDS message
        msg = Uds(i).bytes;
        if isempty(msg)
            continue; % Skip empty messages
        end

        % Check if message is a valid UDS request
        SID = msg(1);  % Service Identifier
        if SID == 97  % 0x21 + 0x40 (Single Byte DID)
            numDID = msg(2);
            data = msg(3:end); % Extract measurement data
        elseif SID == 98  % 0x22 + 0x40 (Double Byte DID)
            numDID = msg(2) * 256 + msg(3);
            data = msg(4:end); % Extract measurement data
        else
            continue; % Skip non-UDS messages
        end

        % Store data in the DID mapping
        if isKey(didMap, numDID)
            entry = didMap(numDID);
            entry.ti(end+1) = Uds(i).ti;
            entry.arrayByte = [entry.arrayByte; data];
            didMap(numDID) = entry;
        else
            didMap(numDID) = struct('numDid', numDID, 'ti', Uds(i).ti(:), 'arrayByte', data);
        end
    end

    % Convert the map to struct array
    didKeys = keys(didMap);
    for i = 1:length(didKeys)
        StructDid(i) = didMap(didKeys{i});
    end
end
