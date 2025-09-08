function orificeSizingGUI()
    % Simple GUI for orifice sizing using MATLAB
    
    fig = uifigure('Name','Orifice Sizing Tool','Position',[100 100 450 350]);
    
    % Mode dropdown
    uilabel(fig,'Position',[20 300 120 22],'Text','Calculation mode:');
    ddMode = uidropdown(fig,'Position',[150 300 120 22], ...
        'Items',{'diameter','pressure'}, 'Value','diameter');
    
    % Fuel tapoff selector dropdown
    uilabel(fig,'Position',[20 260 120 22],'Text','Fuel Tapoff:');
    ddTapoff = uidropdown(fig,'Position',[150 260 120 22], ...
        'Items',{'None','Pre-Reg','Post-Reg'}, 'Value','None');
    
    % Input fields
    uilabel(fig,'Position',[20 220 120 22],'Text','Mass flow rate (kg/s):');
    efFlow = uieditfield(fig,'numeric','Position',[150 220 120 22],'Value',0.01);
    
    uilabel(fig,'Position',[20 180 120 22],'Text','Fluid (REFPROP):');
    efFluid = uieditfield(fig,'text','Position',[150 180 120 22],'Value','OXYGEN');
    
    uilabel(fig,'Position',[20 140 120 22],'Text','Temperature (K):');
    efTemp = uieditfield(fig,'numeric','Position',[150 140 120 22],'Value',300);
    
    uilabel(fig,'Position',[20 100 120 22],'Text','Pressure (kPa):');
    efPress = uieditfield(fig,'numeric','Position',[150 100 120 22],'Value',5000);
    
    uilabel(fig,'Position',[20 60 120 22],'Text','Cd or CdA:');
    efCd = uieditfield(fig,'numeric','Position',[150 60 120 22],'Value',0.9);
    
    % Calculate button
    btnCalc = uibutton(fig,'Text','Calculate','Position',[150 20 120 30], ...
        'ButtonPushedFcn',@(btn,event) calculateOrifice());
    
    % Results label
    resLabel = uilabel(fig,'Position',[20 10 400 30],'Text','Result:');
    
    function calculateOrifice()
        flowRate = efFlow.Value;
        fluid = efFluid.Value;
        temp = efTemp.Value;
        press = efPress.Value;
        cdVal = efCd.Value;
        mode = ddMode.Value;
        tapoff = ddTapoff.Value;
        
        try
            cdaKnown = strcmpi(mode,'pressure');
            [d_mm, p_kPa, flowRes] = sizeOrifice(flowRate, fluid, temp, press, cdVal, mode, tapoff, cdaKnown);
            if strcmpi(mode,'diameter')
                resLabel.Text = sprintf('Orifice diameter = %.3f mm', d_mm);
            else
                resLabel.Text = sprintf('Required pressure = %.1f kPa', p_kPa);
            end
        catch ME
            resLabel.Text = ['Error: ', ME.message];
        end
    end
end
