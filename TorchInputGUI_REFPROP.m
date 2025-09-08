function TorchInputGUI_REFPROP
    % TorchInputGUI_REFPROP: Scrollable, persistent input GUI for torch sizing
    REFPROP_FLUIDS = {'OXYGEN', 'HYDROGEN', 'METHANE', 'NITROGEN', 'ARGON', 'HELIUM', 'AIR'};
    defaultOx = 'OXYGEN'; defaultFuel = 'HYDROGEN';
    figW = 860; figH = 720;
    fig = uifigure('Name','Torch Igniter Inputs (REFPROP-ready, Scrollable)', ...
                   'Position',[100 100 figW figH]);
    panelMargin = 16;
    % Outer scrollable panel container
    scrollPanel = uipanel(fig, ...
        'Units','pixels', ...
        'Position',[panelMargin, panelMargin, figW-2*panelMargin, figH-2*panelMargin], ...
        'Scrollable','on', ...
        'Title','Inputs');
    contentHeight = 1300; % Adjustable for # of fields
    contentPanel = uipanel(scrollPanel, ...
        'Units','pixels', ...
        'Position',[0, 0, scrollPanel.Position(3), contentHeight], ...
        'BorderType','none');
    wLabel = 320; wField = 220; col1x = 20; col2x = col1x + wLabel + 20;
    rowh = 28; pad = 6; r = 0;
    function y = yRow(i), y = contentHeight - (40 + i*(rowh + pad)); end
    H = struct();
    % Fluid dropdowns
    r = r + 1;
    uilabel(contentPanel,'Text','Oxidizer Species (REFPROP key)', 'Position',[col1x,yRow(r),wLabel,rowh]);
    H.ddOx = uidropdown(contentPanel,'Items',REFPROP_FLUIDS,'Value',defaultOx,'Position',[col2x,yRow(r),wField,rowh]);
    r = r + 1;
    uilabel(contentPanel,'Text','Fuel Species (REFPROP key)','Position',[col1x,yRow(r),wLabel,rowh]);
    H.ddFuel = uidropdown(contentPanel,'Items',REFPROP_FLUIDS,'Value',defaultFuel,'Position',[col2x,yRow(r),wField,rowh]);
    % Helper to add numeric field
    function ef = addNum(lbl)
        uilabel(contentPanel,'Text',lbl, 'Position',[col1x,yRow(r+1),wLabel,rowh]);
        ef = uieditfield(contentPanel,'numeric','Position',[col2x,yRow(r+1),wField,rowh]);
        r = r + 1;
    end
    % Add all numeric/other fields
    H.efPoxS   = addNum('Oxidizer Storage Pressure (kPa)');
    H.efPfS    = addNum('Fuel Storage Pressure (kPa)');
    H.efToxS   = addNum('Oxidizer Storage Temperature (K)');
    H.efTfS    = addNum('Fuel Storage Temperature (K)');
    H.efCdOx   = addNum('Oxidizer delivery orifice/channel Cd (-)');
    H.efCdF    = addNum('Fuel delivery orifice/channel Cd (-)');
    H.efDOx    = addNum('Oxidizer delivery orifice/channel diameter (mm)');
    H.efDF     = addNum('Fuel delivery orifice/channel diameter (mm)');
    H.efAexit  = addNum('Torch Exit Area (mm^2)');
    H.efPoxReg = addNum('Oxidizer regulated pressure (kPa)');
    H.efPfReg  = addNum('Fuel regulated pressure (kPa)');
    H.efVch    = addNum('Chamber Volume (mm^3)');
    H.efRuntime= addNum('Runtime (s)');
    H.eftWallTorch  = addNum('Wall thickness (torch combustor AVG) (mm)');
    H.eftWallTrench = addNum('Wall thickness (flame trench) (mm)');
    H.efkWall       = addNum('Wall conductivity (W/(m·K))');
    H.efrhoWall     = addNum('Wall density (kg/m^3)');
    H.efcpWall      = addNum('Wall Cp (J/(kg·K))');
    H.efTamb        = addNum('Ambient temperature (K)');
    H.efPhi         = addNum('Target torch reactant equivalence ratio (Phi)');
    H.efPtMain      = addNum('Main chamber total Pressure (kPa)');
    H.efTtMain      = addNum('Main chamber total Temperature (K)');
    r = r + 1;
    uilabel(contentPanel,'Text','Fuel Tapoff Selector','Position',[col1x,yRow(r),wLabel,rowh]);
    H.ddTap = uidropdown(contentPanel,'Items',{'None','Pre-Reg','Post-Reg'},'Value','None', 'Position',[col2x,yRow(r),wField,rowh]);
    H.efCdTap = addNum('Fuel tapoff orifice Cd (-)');
    H.efD1Tap = addNum('Fuel tapoff orifice diameter 1 (mm)');
    H.efD2Tap = addNum('Fuel tapoff diameter 2 (mm)');
    r = r + 1;
    uilabel(contentPanel,'Text','Feed pressure known?','Position',[col1x,yRow(r),wLabel,rowh]);
    H.ddFeedPressureKnown = uidropdown(contentPanel,'Items',{'Yes','No'},'Value','Yes','Position',[col2x,yRow(r),wField,rowh]);
    r = r + 1;
    uilabel(contentPanel,'Text','Orifice geometry known?','Position',[col1x,yRow(r),wLabel,rowh]);
    H.ddOrificeKnown = uidropdown(contentPanel,'Items',{'Yes','No'},'Value','Yes','Position',[col2x,yRow(r),wField,rowh]);
    r = r + 1;
    % Save and Run Button
    H.btnSave = uibutton(contentPanel,'Text','Save & Run Sizing','Position',[col2x,yRow(r),160,34], ...
        'ButtonPushedFcn',@(btn,ev) saveAndRun());
    % Reload last input values if available
    lastInputFile = 'torchInputs_last.mat';
    if exist(lastInputFile,'file')
        tmp = load(lastInputFile,'S');
        lastInputs = tmp.S;
        fieldmap = { ...
          {'Fuel_Storage_Pressure_kPa','efPfS'}, ...
          {'Oxidizer_Storage_Pressure_kPa','efPoxS'}, ...
          {'Target_EQR','efPhi'}, ...
          {'Fuel_Species_REFPROP','ddFuel'}, ...
          {'Oxidizer_Species_REFPROP','ddOx'} ...
          % Add more mappings as needed for all your fields
        };
        for j = 1:numel(fieldmap)
            if isfield(lastInputs,fieldmap{j}{1}) && isfield(H,fieldmap{j}{2})
                H.(fieldmap{j}{2}).Value = lastInputs.(fieldmap{j}{1});
            end
        end
    end
    
    function [S,msgout] = collectInputStruct()
        S = struct();
        msgout = '';
        try
            S.Oxidizer_Species_REFPROP     = H.ddOx.Value;
            S.Fuel_Species_REFPROP         = H.ddFuel.Value;
            S.Oxidizer_Storage_Pressure_kPa = H.efPoxS.Value;
            S.Fuel_Storage_Pressure_kPa     = H.efPfS.Value;
            S.Oxidizer_Storage_Temperature_K = H.efToxS.Value;
            S.Fuel_Storage_Temperature_K     = H.efTfS.Value;
            S.Oxidizer_Cd                  = H.efCdOx.Value;
            S.Fuel_Cd                      = H.efCdF.Value;
            S.Oxidizer_Diameter_mm         = H.efDOx.Value;
            S.Fuel_Diameter_mm             = H.efDF.Value;
            S.Torch_Exit_Area_mm2          = H.efAexit.Value;
            S.Oxidizer_Regulated_Pressure_kPa = H.efPoxReg.Value;
            S.Fuel_Regulated_Pressure_kPa = H.efPfReg.Value;
            S.Chamber_Volume_mm3           = H.efVch.Value;
            S.Runtime_s                    = H.efRuntime.Value;
            S.Wall_Thickness_Torch_mm      = H.eftWallTorch.Value;
            S.Wall_Thickness_Trench_mm     = H.eftWallTrench.Value;
            S.Wall_Conductivity_W_mK       = H.efkWall.Value;
            S.Wall_Density_kg_m3           = H.efrhoWall.Value;
            S.Wall_Cp_J_kgK                = H.efcpWall.Value;
            S.Ambient_Temperature_K        = H.efTamb.Value;
            S.Target_EQR                   = H.efPhi.Value;
            S.Main_Chamber_Pressure_kPa    = H.efPtMain.Value;
            S.Main_Chamber_Temperature_K   = H.efTtMain.Value;
            S.Fuel_Tapoff_Selector         = H.ddTap.Value;
            S.Fuel_Tapoff_Cd               = H.efCdTap.Value;
            S.Fuel_Tapoff_D1_mm            = H.efD1Tap.Value;
            S.Fuel_Tapoff_D2_mm            = H.efD2Tap.Value;
            S.Feed_Pressure_Known          = H.ddFeedPressureKnown.Value;
            S.Orifice_Geometry_Known       = H.ddOrificeKnown.Value;
        catch ex
            msgout = ['Input collection error: ' ex.message];
        end
    end
    
    % Helper to add missing fields for struct alignment
    function S = ensure_struct_fields(S, fieldList)
        for iFld = 1:numel(fieldList)
            if ~isfield(S, fieldList{iFld})
                S.(fieldList{iFld}) = NaN; % Or other default
            end
        end
    end
    
    function saveAndRun()
        [S,msg] = collectInputStruct();
        if ~isempty(msg)
            uialert(fig, msg, 'Input Error','Icon','warning');
            return;
        end
        % Simple input validation example
        criticalFields = {'Oxidizer_Storage_Pressure_kPa','Fuel_Storage_Pressure_kPa','Target_EQR'};
        for kFld = 1:numel(criticalFields)
            val = S.(criticalFields{kFld});
            if ~isfinite(val) || val < 0
                uialert(fig, sprintf('Invalid value for %s.', criticalFields{kFld}), ...
                    'Input Error','Icon','warning');
                return;
            end
        end

        % Save inputs persistently
        try
            save('torchInputs_last.mat','S');
        catch ex
            uialert(fig,['Could not save inputs: ' ex.message],'Save Failed','Icon','error');
            return;
        end

        % Assign in base workspace for inspection
        assignin('base','torchInputs',S);

        % Run your orifice sizing func - replace with name if different
        try
            results = runTorchOrificeSizingMaster(S);
        catch ex
            uialert(fig,['Sizing error: ' ex.message],'Computation Failed','Icon','error');
            return;
        end

        % Check results OK
        if isfield(results,'ok') && ~results.ok
            uialert(fig, results.message, 'Input Needed', 'Icon','warning');
            return;
        end

        wildFields = {'orificeDiam_ox_mm','orificeDiam_fuel_mm', ...
                      'massFlow_ox_kgps','massFlow_fuel_kgps', ...
                      'massFlow_ox_gps','massFlow_fuel_gps'};
        for kFld = 1:numel(wildFields)
            val = results.(wildFields{kFld});
            if ~isfinite(val) || isnan(val) || abs(val) > 1e6
                uialert(fig, sprintf('Wild output for %s. Likely input error.',wildFields{kFld}), ...
                    'Computation Warning','Icon','warning');
                return;
            end
        end

        % Load previous results for concatenation or initialize new
        if exist('torch_results_all.mat','file')
            tmp = load('torch_results_all.mat','results_all');
            results_all = tmp.results_all;
            % Align new results fields
            results = ensure_struct_fields(results, fieldnames(results_all));
            % Also ensure existing results_all have all fields in new results
            allFields = fieldnames(results);
            for idx = 1:numel(results_all)
                results_all(idx) = ensure_struct_fields(results_all(idx), allFields);
            end
            results_all = [results_all; results];
        else
            results_all = results;
        end

        % Save updated results array
        try
            save('torch_results_all.mat','results_all','-v7.3');
        catch ex
            uialert(fig,['Could not save results: ' ex.message],'Save Error','Icon','error');
            return;
        end

        % Show results message
        if isfield(results,'message') && ~isempty(results.message)
            uialert(fig, results.message, 'Sizing Results', 'Icon','success');
        else
            uialert(fig, ...
                sprintf([ ...
                    'Orifice sizing complete.\n' ...
                    'Ox Diameter: %.3f mm | Fuel Diameter: %.3f mm\n' ...
                    'Ox Mass Flow: %.4f g/s | Fuel Mass Flow: %.4f g/s'], ...
                    results.orificeDiam_ox_mm, results.orificeDiam_fuel_mm, ...
                    results.massFlow_ox_gps, results.massFlow_fuel_gps), ...
                'Success','Icon','success');
        end
        disp(results);
    end
end
