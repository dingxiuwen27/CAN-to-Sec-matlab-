function highlightTableCells(hdl, numRows, startNum, rangeHighlight, highlightColor, numLab, error)
    % Define column labels (right to left)
    colLabels = {'b0', 'b1', 'b2', 'b3', 'b4', 'b5', 'b6', 'b7'};

    % Generate data for table (increase from right to left)
    numCols = length(colLabels);
    data = reshape(1:(numRows * numCols), numCols, numRows)';
    data = fliplr(data); % Reverse column order to go right to left

    % Determine font size based on figure size
    fontSize = 6;

    % Add highlights to existing table
    hold on;
    for row = 1:numRows
        for col = 1:numCols
            cellValue = data(row, col);

            % Check if cell is in highlight range
            if (cellValue >= startNum) && (cellValue < startNum + rangeHighlight)
                % Draw a transparent rectangle over the existing one
                rectangle(hdl, 'Position', [col, -row, 1, 1], 'FaceColor', highlightColor, 'EdgeColor', 'k');

                % Update text inside the cell to include numLab
                displayText = sprintf('%d: [%d]: %0.1f%%', cellValue, numLab, error);
                text(hdl, col + 0.5, -row + 0.5, displayText, ...
                    'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
                    'FontSize', fontSize, 'FontWeight', 'bold');
               else continue;
            end
        end
    end
    hold off;
end
