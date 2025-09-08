function inputs = parseTorchInputs(S)
    % Parse and verify torch input struct from GUI
    % Convert zero values to NaN for easier handling
    fields = fieldnames(S);
    inputs = struct();
    for i = 1:length(fields)
        val = S.(fields{i});
        if isnumeric(val) && val == 0
            inputs.(fields{i}) = NaN;
        else
            inputs.(fields{i}) = val;
        end
    end
    
    % Additional validation can be added here if needed
    
end
