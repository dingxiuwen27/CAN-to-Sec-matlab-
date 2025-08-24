function drawBaseTable(hdl, numRows)
    set(hdl, 'Visible', 'off')
    
    % Define column labels 
    colLabels = {'b7', 'b6', 'b5', 'b4', 'b3', 'b2', 'b1', 'b0'};
    
    % Generate data for table (increase from right to left)
    numCols = length(colLabels);
    data = reshape(1:(numRows * numCols), numCols, numRows)';
    data = fliplr(data); % Reverse column order to go right to left

    % Convert to cell array for display
    dataCell = arrayfun(@num2str, data, 'UniformOutput', false);

    % Determine font size based on figure size
    fontSize = 6;

    % Display table using text objects
    hold on;
    for row = 1:numRows
        for col = 1:numCols
            cellValue = data(row, col);

            % Draw rectangle with a white background
            rectangle(hdl, 'Position', [col, -row, 1, 1], 'FaceColor', [1,1,1], 'EdgeColor', 'k');

            % Add text to cell (only number)
            text(hdl, col + 0.5, -row + 0.5, dataCell{row, col}, ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
                'FontSize', fontSize);
        end
    end

    % Draw column labels
    for col = 1:numCols
        text(hdl, col + 0.5, 0.5, colLabels{col}, 'HorizontalAlignment', 'center', ...
            'VerticalAlignment', 'bottom', 'FontSize', fontSize, 'Color', 'k');
    end

    hold off;
end
