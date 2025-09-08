function masterTorchOrificeGUI()
    % MASTER GUI to input torch parameters and perform orifice sizing
    
    % --- Create main figure ---
    fig = uifigure('Name','Torch Inputs and Orifice Sizing','Position',[100 100 900 750]);
    
    % --- Create containers ---
    leftPanel = uipanel(fig,'Title','Torch Igniter Inputs','Position',[10 10 420 720]);
    rightPanel = uipanel(fig,'Title','Orifice Sizing','Position',[440 10 440 720]);
    
    % --- Build torch input GUI components in leftPanel (based on your GUI code) ---
    % For brevity, only a subset of inputs shown here, can expand as needed
    
    % Example inputs:
    uilabel(leftPanel,'Text','Oxidizer Species (REFPROP):','Position',[10 670 200 22]);
    ddOx = uidropdown(leftPanel,'Items',{'OXYGEN','HYDROGEN','METHANE','NITROGEN','ARGON','HELIUM','AIR'},...
                     'Value','OXYGEN','Position',[220 670 180 22]);
    
    uilabel(leftPanel,'Text','Fuel Species (REFPROP):','Position',[10 630 200 22]);
    ddFuel = uidropdown(leftPanel,'Items',{'OXYGEN','HYDROGEN','METHANE','NITROGEN','ARGON','HELIUM','AIR'},...
                       'Value','HYDROGEN','Position',[220 630 180 22]);
    
    uilabel(leftPanel,'Text','Oxidizer Storage Pressure (kPa):','Position',[10 590 200 22]);
    efPoxS = uieditfield(leftPanel,'numeric','Value',25000,'Position',[220 590 180 22]);
    
    uilabel(leftPanel,'Text','Fuel Storage Pressure (kPa):','Position',[10 550 200 22]);
    efPfS = uieditfield(leftPanel,'numeric','Value',25000,'Position',[220 550 180 22]);
    
    uilabel(leftPanel,'Text','Oxidizer Storage Temperature (K):','Position',[10 510 200 22]);
    efToxS = uieditfield(leftPanel,'numeric','Value',300,'Position',[220 510 180 22]);
    
    uilabel(leftPanel,'Text','Fuel Storage Temperature (K):','Position',[10 470 200 22]);
    efTfS = uieditfield(leftPanel,'numeric','Value',300,'Position',[220 470 180 22]);
    
    uilabel(leftPanel,'Text','Fuel Tapoff Selector:','Position',[10 430 200 22]);
    ddTap = uidropdown(leftPanel,'Items',{'None','Pre-Reg','Post-Reg'},'Value','None','Position',[220 430 180 22]);
    
    % Add Cd inputs for oxidizer and fuel
    uilabel(leftPanel,'Text','Oxidizer Cd:','Position',[10 390 200 22]);
    efCdOx = uieditfield(leftPanel,'numeric','Value',0.9,'Position',[220 390 180 22]);
    
    uilabel(leftPanel,'Text','Fuel Cd:','Position',[10 350 200 22]);
    efCdF = uieditfield(leftPanel,'numeric','Value',0.9,'Position',[220 350 180 22]);
    
    % Mass flow rates inputs for sizing (example values)
    uilabel(leftPanel,'Text','Oxidizer Mass Flow (kg/s):','Position',[10 310 200 22]);
    efMFOx = uieditfield(leftPanel,'numeric','Value',0.02,'Position',[220 310 180 22]);
    
    uilabel(leftPanel,'Text','Fuel Mass Flow (kg/s):','Position',[10 270 200 22]);
    efMFF = uieditfield(leftPanel,'numeric','Value',0.01,'Position',[220 270 180 22]);
    
    % Button to submit inputs and run sizing
    btnRun = uibutton(leftPanel,'Text','Run Orifice Sizing',...
                      'Position',[150 220 120 30],'ButtonPushedFcn',@(btn,event) runSizing());
    
    % --- Results area in rightPanel ---
    resText = uitextarea(rightPanel,'Editable','off','Position',[10 10 420 700]);
    
    % --- Callback function to collect inputs, run sizing for both orifices and show results ---
    function runSizing()
        % Collect inputs into struct (similar to your GUI struct)
        S = struct();
        S.Oxidizer_Species_REFPROP = ddOx.Value;
        S.Fuel_Species_REFPROP = ddFuel.Value;
        S.Oxidizer_Storage_Pressure_kPa = efPoxS.Value;
        S.Fuel_Storage_Pressure_kPa = efPfS.Value;
        S.Oxidizer_Storage_Temperature_K = efToxS.Value;
        S.Fuel_Storage_Temperature_K = efTfS.Value;
        S.Fuel_Tapoff_Selector = ddTap.Value;
        S.Oxidizer_Cd = efCdOx.Value;
        S.Fuel_Cd = efCdF.Value;
        S.Oxidizer_MassFlow_kg_s = efMFOx.Value;
        S.Fuel_MassFlow_kg_s = efMFF.Value;
        
        % Parse inputs (conversion/validation if required)
        inputs = parseTorchInputs(S);
        
        % Run orifice sizing for oxidizer
        [dOx_mm, ~, ~] = sizeOrifice(inputs.Oxidizer_MassFlow_kg_s, inputs.Oxidizer_Species_REFPROP, ...
                                    inputs.Oxidizer_Storage_Temperature_K, inputs.Oxidizer_Storage_Pressure_kPa, ...
                                    inputs.Oxidizer_Cd, 'diameter', inputs.Fuel_Tapoff_Selector, false);
        
        % Run orifice sizing for fuel
        [dF_mm, ~, ~] = sizeOrifice(inputs.Fuel_MassFlow_kg_s, inputs.Fuel_Species_REFPROP, ...
                                   inputs.Fuel_Storage_Temperature_K, inputs.Fuel_Storage_Pressure_kPa, ...
                                   inputs.Fuel_Cd, 'diameter', inputs.Fuel_Tapoff_Selector, false);
        
        % Display results
        txt = sprintf('Orifice Sizing Results:\n\nOxidizer Diameter: %.3f mm\nFuel Diameter: %.3f mm\n', dOx_mm, dF_mm);
        
        % Add tapoff info if any
        if ~strcmpi(inputs.Fuel_Tapoff_Selector, 'None')
            txt = [txt, sprintf('Fuel Tapoff present: %s\n', inputs.Fuel_Tapoff_Selector)];
        else
            txt = [txt, 'No Fuel Tapoff present\n'];
        end
        
        resText.Value = txt;
    end
end
