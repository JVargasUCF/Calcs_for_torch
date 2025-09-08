function results = runTorchOrificeSizingMaster(torchInputs)
    % Receive torchInputs struct
    % Parse values
    S = parseTorchInputs(torchInputs);
    
    % Run sizing and flow calculations
    results = sizeOrifice(S);
    
    % Possible extension: store results in base workspace or GUI outputs
    
    % Display summary
    fprintf('Orifice sizing results:\n');
    fprintf('Oxidizer diameter: %.3f mm\n', results.orificeDiam_ox_mm);
    fprintf('Fuel diameter: %.3f mm\n', results.orificeDiam_fuel_mm);
    fprintf('Oxidizer feed pressure: %.1f kPa\n', results.pressure_ox_kPa);
    fprintf('Fuel feed pressure: %.1f kPa\n', results.pressure_fuel_kPa);
    fprintf('Oxidizer mass flow: %.4f mg/s\n', results.massFlow_ox_gps);
    fprintf('Fuel mass flow: %.4f mg/s\n', results.massFlow_fuel_gps);
end
