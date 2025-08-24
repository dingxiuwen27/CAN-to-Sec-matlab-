function VAL = getByteStream(CAN)
    numBitsMax = 16;
    numBytes = width(CAN.arrayByte);
    for numBits = 1:numBitsMax
        VAL(numBits).ti = CAN.ti - CAN.ti(1);

        for idxBit = 1: (8 * numBytes - numBits + 1)
            idxByte1 = ceil(idxBit / 8);
            idxByte2 = ceil((idxBit + numBits - 1) / 8);

            if idxByte1 == idxByte2  % Mask fits within one byte
                byteChannel = CAN.arrayByte(:,idxByte1);
            else
                byteChannel = CAN.arrayByte(:,idxByte1) * 256 + CAN.arrayByte(:,idxByte2);
            end

            % Compute the correct bit shift
            idxBitStrt = mod(idxBit-1, 8);
            byteChannel = bitshift(byteChannel, -idxBitStrt);
            byteChannel = bitand(byteChannel, 2^numBits - 1); % Extract the correct numBits
            % Store extracted value
            VAL(numBits).arrayVal(:, idxBit) = byteChannel;
            % Store extracted value as normalized 
            minByteChannel = min(byteChannel);
            maxByteChannel = max(byteChannel);
            if minByteChannel~=maxByteChannel
                VAL(numBits).arrayValNrm(:, idxBit) = (byteChannel-minByteChannel)/(maxByteChannel-minByteChannel);
            else
                VAL(numBits).arrayValNrm(:, idxBit) = zeros(size(byteChannel));
            end
        end
        VAL(numBits).numBits = numBits;
    end
end
