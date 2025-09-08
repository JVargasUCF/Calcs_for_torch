function results = sizeOrifice(S)
% sizeOrifice (compressible isentropic + isenthalpic throttling + post-reg tap-off A)
% Ideal regulator model: tap-off branch is independent of torch branch (P0 fixed).
% Computes tap-off mass flow if S.Fuel_Tapoff_Selector == 'Post-Reg'.
    % Toggles
    targetPhi         = S.Target_EQR;
    feedPressureKnown = strcmpi(S.Feed_Pressure_Known,'Yes');
    orificeKnown      = strcmpi(S.Orifice_Geometry_Known,'Yes');
    % Stoichiometric O/F for H2/O2
    stoichMassRatio = 8;
    % Downstream (entry) pressure (kPa abs)
    Pd_kPa = 101.325;
    if isfield(S,'Main_Chamber_Pressure_kPa') && isfinite_num(S.Main_Chamber_Pressure_kPa)
        Pd_kPa = max(101, S.Main_Chamber_Pressure_kPa);
    end
    % Optional: tap-off sink pressure (defaults to Pd_kPa)
    Pd_tap_kPa = Pd_kPa;
    if isfield(S,'Tapoff_Downstream_Pressure_kPa') && isfinite_num(S.Tapoff_Downstream_Pressure_kPa)
        Pd_tap_kPa = max(50, S.Tapoff_Downstream_Pressure_kPa); % simple sanity floor
    end
    % Init outputs
    results = struct();
    results.orificeDiam_ox_mm   = NaN;
    results.orificeDiam_fuel_mm = NaN;
    results.pressure_ox_kPa     = NaN;  % upstream/feed abs
    results.pressure_fuel_kPa   = NaN;
    results.massFlow_ox_kgps    = NaN;
    results.massFlow_fuel_kgps  = NaN;
    results.massFlow_ox_gps     = NaN;
    results.massFlow_fuel_gps   = NaN;
    results.mdot_fuel_tap_kgps  = 0;    % tap-off mass flow (independent branch)
    results.mdot_fuel_tap_gps   = 0;    % tap-off mass flow in g/s
    results.mode    = '';
    results.ok      = true;
    results.message = '';
    % ---- Storage enthalpies (basis for isenthalpic throttling) ----
    h_storage_ox = refpropm('H','T',S.Oxidizer_Storage_Temperature_K, ...
                               'P',S.Oxidizer_Storage_Pressure_kPa, S.Oxidizer_Species_REFPROP); % J/kg
    h_storage_f  = refpropm('H','T',S.Fuel_Storage_Temperature_K, ...
                               'P',S.Fuel_Storage_Pressure_kPa, S.Fuel_Species_REFPROP);         % J/kg
    % Helper: pick feed P (prefer regulated if present)
    function PkPa = choose_feed_pressure_kPa(P_reg_kPa, P_stor_kPa)
        if isfinite_num(P_reg_kPa)
            PkPa = P_reg_kPa;
        else
            PkPa = P_stor_kPa;
        end
    end
    % ------------- CASES -------------
    if feedPressureKnown && orificeKnown
        % Case A: known feed P and known d -> compute mdot (compressible)
        results.mode = 'pass_through';
        P0_ox_kPa = choose_feed_pressure_kPa(S.Oxidizer_Regulated_Pressure_kPa, S.Oxidizer_Storage_Pressure_kPa);
        P0_f_kPa  = choose_feed_pressure_kPa(S.Fuel_Regulated_Pressure_kPa,     S.Fuel_Storage_Pressure_kPa);
        % Upstream line (stagnation) states (isenthalpic from storage)
        [T0_ox, rho_up_ox, R_ox, gamma_ox] = upstream_isenthl_state(h_storage_ox, P0_ox_kPa, S.Oxidizer_Species_REFPROP);
        [T0_f,  rho_up_f,  R_f,  gamma_f ] = upstream_isenthl_state(h_storage_f,  P0_f_kPa,  S.Fuel_Species_REFPROP);
        % Entry (post-orifice) states for reporting/thermal
        [T_entry_ox, rho_entry_ox] = entry_isenthl_state(h_storage_ox, Pd_kPa, S.Oxidizer_Species_REFPROP);
        [T_entry_f,  rho_entry_f ] = entry_isenthl_state(h_storage_f,  Pd_kPa, S.Fuel_Species_REFPROP);
        % Areas
        d_ox_mm   = S.Oxidizer_Diameter_mm;
        d_fuel_mm = S.Fuel_Diameter_mm;
        A_ox   = area_from_d_mm(d_ox_mm);
        A_fuel = area_from_d_mm(d_fuel_mm);
        % Mass flux (choked/unchoked) and mdot (torch)
        G_ox = mass_flux_isentropic(P0_ox_kPa, T0_ox, Pd_kPa, gamma_ox, R_ox);
        G_f  = mass_flux_isentropic(P0_f_kPa,  T0_f,  Pd_kPa, gamma_f,  R_f );
        mOx  = S.Oxidizer_Cd * A_ox   * G_ox;
        mF   = S.Fuel_Cd     * A_fuel * G_f;
        % Tap-off flow (independent branch)
        results.mdot_fuel_tap_kgps = compute_tapoff_mdot(S, P0_f_kPa, T0_f, gamma_f, R_f, Pd_tap_kPa);
        results.mdot_fuel_tap_gps  = results.mdot_fuel_tap_kgps * 1000;
        % Save
        results.pressure_ox_kPa     = P0_ox_kPa;
        results.pressure_fuel_kPa   = P0_f_kPa;
        results.orificeDiam_ox_mm   = d_ox_mm;
        results.orificeDiam_fuel_mm = d_fuel_mm;
        results.massFlow_ox_kgps    = mOx;
        results.massFlow_fuel_kgps  = mF;
        % Convert for reporting to g/s
        results.massFlow_ox_gps = mOx * 1000;
        results.massFlow_fuel_gps = mF * 1000;
        % States (nice to have)
        results.T_up_ox_K = T0_ox;   results.rho_up_ox = rho_up_ox;
        results.T_up_fuel_K = T0_f;  results.rho_up_fuel = rho_up_f;
        results.T_entry_ox_K = T_entry_ox; results.rho_entry_ox = rho_entry_ox;
        results.T_entry_fuel_K = T_entry_f; results.rho_entry_fuel = rho_entry_f;
        results.message = sprintf([ ...
            'Pass-through (compressible). P0_f=%.1f, P0_ox=%.1f kPa; Pd=%.1f kPa\n' ...
            'd_f=%.3f mm, d_ox=%.3f mm | m_f=%.4f g/s, m_ox=%.4f g/s | m_tap=%.4f g/s'], ...
            P0_f_kPa, P0_ox_kPa, Pd_kPa, d_fuel_mm, d_ox_mm, results.massFlow_fuel_gps, results.massFlow_ox_gps, results.mdot_fuel_tap_gps);

    elseif feedPressureKnown && ~orificeKnown
        % Case B: known feed P, unknown d -> size d for target flows
        results.mode = 'size_diameters';
        P0_ox_kPa = choose_feed_pressure_kPa(S.Oxidizer_Regulated_Pressure_kPa, S.Oxidizer_Storage_Pressure_kPa);
        P0_f_kPa  = choose_feed_pressure_kPa(S.Fuel_Regulated_Pressure_kPa,     S.Fuel_Storage_Pressure_kPa);
        [T0_ox, rho_up_ox, R_ox, gamma_ox] = upstream_isenthl_state(h_storage_ox, P0_ox_kPa, S.Oxidizer_Species_REFPROP);
        [T0_f,  rho_up_f,  R_f,  gamma_f ] = upstream_isenthl_state(h_storage_f,  P0_f_kPa,  S.Fuel_Species_REFPROP);
        [T_entry_ox, rho_entry_ox] = entry_isenthl_state(h_storage_ox, Pd_kPa, S.Oxidizer_Species_REFPROP);
        [T_entry_f,  rho_entry_f ] = entry_isenthl_state(h_storage_f,  Pd_kPa, S.Fuel_Species_REFPROP);
        % Fuel flow guess
        fuelFlow = NaN;
        if isfinite_num(S.Fuel_Diameter_mm)
            A_f_guess = area_from_d_mm(S.Fuel_Diameter_mm);
            G_f_guess = mass_flux_isentropic(P0_f_kPa, T0_f, Pd_kPa, gamma_f, R_f);
            fuelFlow  = S.Fuel_Cd * A_f_guess * G_f_guess;
        else
            fuelFlow = 0.01; % kg/s fallback guess
        end
        oxFlow = fuelFlow * stoichMassRatio / targetPhi;
        % Mass fluxes
        G_f  = mass_flux_isentropic(P0_f_kPa,  T0_f,  Pd_kPa, gamma_f,  R_f );
        G_ox = mass_flux_isentropic(P0_ox_kPa, T0_ox, Pd_kPa, gamma_ox, R_ox);
        % Areas and diameters
        A_fuel = fuelFlow / (S.Fuel_Cd * G_f);
        A_ox   = oxFlow   / (S.Oxidizer_Cd * G_ox);
        d_fuel_mm = d_from_area_m2(A_fuel);
        d_ox_mm   = d_from_area_m2(A_ox);
        % Tap-off flow
        results.mdot_fuel_tap_kgps = compute_tapoff_mdot(S, P0_f_kPa, T0_f, gamma_f, R_f, Pd_tap_kPa);
        results.mdot_fuel_tap_gps  = results.mdot_fuel_tap_kgps * 1000;
        results.pressure_fuel_kPa   = P0_f_kPa;
        results.pressure_ox_kPa     = P0_ox_kPa;
        results.orificeDiam_fuel_mm = d_fuel_mm;
        results.orificeDiam_ox_mm   = d_ox_mm;
        results.massFlow_fuel_kgps  = fuelFlow;
        results.massFlow_ox_kgps    = oxFlow;
        results.massFlow_fuel_gps   = fuelFlow * 1000;
        results.massFlow_ox_gps     = oxFlow   * 1000;
        results.T_up_ox_K = T0_ox;   results.rho_up_ox = rho_up_ox;
        results.T_up_fuel_K = T0_f;  results.rho_up_fuel = rho_up_f;
        results.T_entry_ox_K = T_entry_ox; results.rho_entry_ox = rho_entry_ox;
        results.T_entry_fuel_K = T_entry_f; results.rho_entry_fuel = rho_entry_f;
        results.message = sprintf([ ...
            'Sized diameters (compressible). P0_f=%.1f, P0_ox=%.1f kPa; Pd=%.1f kPa\n' ...
            'd_f=%.3f mm, d_ox=%.3f mm | m_f=%.4f g/s, m_ox=%.4f g/s (ϕ=%.2f) | m_tap=%.4f g/s'], ...
            P0_f_kPa, P0_ox_kPa, Pd_kPa, d_fuel_mm, d_ox_mm, results.massFlow_fuel_gps, results.massFlow_ox_gps, targetPhi, results.mdot_fuel_tap_gps);

    elseif ~feedPressureKnown && orificeKnown
        % Case C: unknown feed P, known d -> solve required P0 for target flows
        results.mode = 'solve_pressures';
        if ~isfinite_num(S.Fuel_Diameter_mm) || ~isfinite_num(S.Oxidizer_Diameter_mm)
            results.ok = false;
            results.message = 'Provide Fuel and Ox diameters to solve feed pressures.';
            return;
        end
        
        % Geometry areas
        A_fuel = area_from_d_mm(S.Fuel_Diameter_mm);
        A_ox   = area_from_d_mm(S.Oxidizer_Diameter_mm);
        maxP0_guess = 5000; % max pressure guess [kPa]
        
        % Max fuel flow possible at max pressure
        [T0f_max, ~, Rf, gammaf] = upstream_isenthl_state(h_storage_f, maxP0_guess, S.Fuel_Species_REFPROP);
        Gf_max = mass_flux_isentropic(maxP0_guess, T0f_max, Pd_kPa, gammaf, Rf);
        fuelFlow_possible = S.Fuel_Cd * A_fuel * Gf_max; % kg/s
        target_fuelFlow = 0.95 * fuelFlow_possible; % use 95% for safety
        
        % Corresponding oxidizer flow for phi target
        oxFlow   = target_fuelFlow * stoichMassRatio / targetPhi;
        fuelFlow = target_fuelFlow;

        % Solve feed pressures
        P0_f_kPa  = solve_P0_for_mdot(fuelFlow, S.Fuel_Cd,     A_fuel, Pd_kPa, h_storage_f,  S.Fuel_Species_REFPROP);
        P0_ox_kPa = solve_P0_for_mdot(oxFlow,   S.Oxidizer_Cd, A_ox,   Pd_kPa, h_storage_ox, S.Oxidizer_Species_REFPROP);

        if isnan(P0_f_kPa) || isnan(P0_ox_kPa)
            results.ok = false;
            results.message = 'Solver failed: unable to find feed pressures with given inputs. Check diameters, Cd, or target flow.';
            return;
        end

        % Upstream states at solved P0
        [T0_f,  rho_up_f,  R_f,  gamma_f ] = upstream_isenthl_state(h_storage_f,  P0_f_kPa,  S.Fuel_Species_REFPROP);
        [T0_ox, rho_up_ox, R_ox, gamma_ox] = upstream_isenthl_state(h_storage_ox, P0_ox_kPa, S.Oxidizer_Species_REFPROP);
        % Entry states (reporting)
        [T_entry_ox, rho_entry_ox] = entry_isenthl_state(h_storage_ox, Pd_kPa, S.Oxidizer_Species_REFPROP);
        [T_entry_f,  rho_entry_f ] = entry_isenthl_state(h_storage_f,  Pd_kPa, S.Fuel_Species_REFPROP);
        % Tap-off flow
        results.mdot_fuel_tap_kgps = compute_tapoff_mdot(S, P0_f_kPa, T0_f, gamma_f, R_f, Pd_tap_kPa);
        results.mdot_fuel_tap_gps  = results.mdot_fuel_tap_kgps * 1000;
        % Save results
        results.pressure_fuel_kPa   = P0_f_kPa;
        results.pressure_ox_kPa     = P0_ox_kPa;
        results.orificeDiam_fuel_mm = S.Fuel_Diameter_mm;
        results.orificeDiam_ox_mm   = S.Oxidizer_Diameter_mm;
        results.massFlow_fuel_kgps  = fuelFlow;
        results.massFlow_ox_kgps    = oxFlow;
        results.massFlow_fuel_gps   = fuelFlow * 1000;
        results.massFlow_ox_gps     = oxFlow   * 1000;
        results.T_up_ox_K = T0_ox;   results.rho_up_ox = rho_up_ox;
        results.T_up_fuel_K = T0_f;  results.rho_up_fuel = rho_up_f;
        results.T_entry_ox_K = T_entry_ox; results.rho_entry_ox = rho_entry_ox;
        results.T_entry_fuel_K = T_entry_f; results.rho_entry_fuel = rho_entry_f;
        results.message = sprintf([ ...
            'Solved feed pressures (compressible). Pd=%.1f kPa\n' ...
            'P0_f=%.1f kPa, P0_ox=%.1f kPa | m_f=%.4f g/s, m_ox=%.4f g/s (ϕ=%.2f) | m_tap=%.4f g/s'], ...
            Pd_kPa, P0_f_kPa, P0_ox_kPa, results.massFlow_fuel_gps, results.massFlow_ox_gps, targetPhi, results.mdot_fuel_tap_gps);

        
    else
        % Case D: both unknown -> compute flows from d & P fields if any
        results.mode = 'compute_flows_from_inputs';
        if ~isfinite_num(S.Fuel_Diameter_mm) || ~isfinite_num(S.Oxidizer_Diameter_mm) || ...
           ~isfinite_num(S.Fuel_Storage_Pressure_kPa) || ~isfinite_num(S.Oxidizer_Storage_Pressure_kPa)
            results.ok = false;
            results.message = 'Provide diameters and pressures or choose a solving mode.';
            return;
        end
        P0_ox_kPa = choose_feed_pressure_kPa(S.Oxidizer_Regulated_Pressure_kPa, S.Oxidizer_Storage_Pressure_kPa);
        P0_f_kPa  = choose_feed_pressure_kPa(S.Fuel_Regulated_Pressure_kPa,     S.Fuel_Storage_Pressure_kPa);
        [T0_ox, rho_up_ox, R_ox, gamma_ox] = upstream_isenthl_state(h_storage_ox, P0_ox_kPa, S.Oxidizer_Species_REFPROP);
        [T0_f,  rho_up_f,  R_f,  gamma_f ] = upstream_isenthl_state(h_storage_f,  P0_f_kPa,  S.Fuel_Species_REFPROP);
        [T_entry_ox, rho_entry_ox] = entry_isenthl_state(h_storage_ox, Pd_kPa, S.Oxidizer_Species_REFPROP);
        [T_entry_f,  rho_entry_f ] = entry_isenthl_state(h_storage_f,  Pd_kPa, S.Fuel_Species_REFPROP);
        d_ox_mm   = S.Oxidizer_Diameter_mm;
        d_fuel_mm = S.Fuel_Diameter_mm;
        A_ox   = area_from_d_mm(d_ox_mm);
        A_fuel = area_from_d_mm(d_fuel_mm);
        G_ox = mass_flux_isentropic(P0_ox_kPa, T0_ox, Pd_kPa, gamma_ox, R_ox);
        G_f  = mass_flux_isentropic(P0_f_kPa,  T0_f,  Pd_kPa, gamma_f,  R_f );
        mOx  = S.Oxidizer_Cd * A_ox   * G_ox;
        mF   = S.Fuel_Cd     * A_fuel * G_f;
        % Tap-off flow
        results.mdot_fuel_tap_kgps = compute_tapoff_mdot(S, P0_f_kPa, T0_f, gamma_f, R_f, Pd_tap_kPa);
        results.mdot_fuel_tap_gps  = results.mdot_fuel_tap_kgps * 1000;
        results.pressure_ox_kPa     = P0_ox_kPa;
        results.pressure_fuel_kPa   = P0_f_kPa;
        results.orificeDiam_ox_mm   = d_ox_mm;
        results.orificeDiam_fuel_mm = d_fuel_mm;
        results.massFlow_ox_kgps    = mOx;
        results.massFlow_fuel_kgps  = mF;
        results.massFlow_ox_gps     = mOx * 1000;
        results.massFlow_fuel_gps   = mF * 1000;
        results.T_up_ox_K = T0_ox;   results.rho_up_ox = rho_up_ox;
        results.T_up_fuel_K = T0_f;  results.rho_up_fuel = rho_up_f;
        results.T_entry_ox_K = T_entry_ox; results.rho_entry_ox = rho_entry_ox;
        results.T_entry_fuel_K = T_entry_f; results.rho_entry_fuel = rho_entry_f;
        results.message = sprintf([ ...
            'Computed flows (compressible). P0_f=%.1f, P0_ox=%.1f kPa; Pd=%.1f kPa\n' ...
            'd_f=%.3f mm, d_ox=%.3f mm | m_f=%.4f g/s, m_ox=%.4f g/s | m_tap=%.4f g/s'], ...
            P0_f_kPa, P0_ox_kPa, Pd_kPa, d_fuel_mm, d_ox_mm, results.massFlow_fuel_gps, results.massFlow_ox_gps, results.mdot_fuel_tap_gps);
    end
    % --------- helper functions ----------
    function tf = isfinite_num(x)
        tf = ~(isempty(x) || ~isnumeric(x) || any(~isfinite(x)));
    end
    function A = area_from_d_mm(d_mm)
        A = pi * ((d_mm/1000)/2)^2;
    end
    function d_mm = d_from_area_m2(A)
        d_mm = 2*sqrt(A/pi)*1000;
    end
    function [T0_K, rho_up, R, gamma] = upstream_isenthl_state(hJpkg, P0_kPa, fluid)
        T0_K = refpropm('T','P',P0_kPa,'H',hJpkg, fluid);
        rho_up = refpropm('D','T',T0_K,'P',P0_kPa, fluid);
        a = refpropm('W','T',T0_K,'P',P0_kPa, fluid);
        M = refpropm('M','T',T0_K,'P',P0_kPa, fluid);
        R = 8314.462618 / M;
        gamma = (a^2) / (R*T0_K);
    end
    function [T_entry, rho_entry] = entry_isenthl_state(hJpkg, Pd_kPa_in, fluid)
        T_entry = refpropm('T','P',Pd_kPa_in,'H',hJpkg, fluid);
        rho_entry = refpropm('D','T',T_entry,'P',Pd_kPa_in, fluid);
    end
    function G = mass_flux_isentropic(P0_kPa, T0, Pd_kPa_in, gamma, R)
        P0 = P0_kPa*1000;  Pd = Pd_kPa_in*1000;
        if Pd >= P0
            G = 0;
            return;
        end
        pr = Pd/P0;
        pr_crit = (2/(gamma+1))^(gamma/(gamma-1));
        coeff = sqrt(gamma/(R*T0));
        if pr <= pr_crit
            G = P0 * coeff * (2/(gamma+1))^((gamma+1)/(2*(gamma-1)));
        else
            term = (pr)^(1/gamma);
            G = P0 * coeff * term * sqrt( (2*gamma)/(gamma-1) * ( (pr)^((gamma-1)/gamma) - pr ) );
        end
    end
    function P0_kPa = solve_P0_for_mdot(mdot_target, Cd, A, Pd_kPa_in, hJpkg, fluid)
        if mdot_target <= 0 || Cd <= 0 || A <= 0
            P0_kPa = NaN;
            return;
        end
        Pmin = Pd_kPa_in + 1;
        Pmax = max(Pd_kPa_in + 1, 5*Pd_kPa_in);
        f = @(P0) mdot_from_P0(P0) - mdot_target;
        while f(Pmax) < 0 && Pmax < 1e4
            Pmax = Pmax * 1.8;
        end
        fPmin = f(Pmin);
        fPmax = f(Pmax);
        if sign(fPmin) == sign(fPmax)
            % No root bracket found: fail gracefully
            P0_kPa = NaN;
            % Since function does not have access to results here, print warning or use error
            warning(['Cannot solve for upstream pressure: function values at interval endpoints have same sign. ' ...
                     sprintf('f(Pmin)=%.4g, f(Pmax)=%.4g',fPmin,fPmax)]);
            return;
        end
        P0_kPa = fzero(@(x) f(x), [Pmin, Pmax]);
        function md = mdot_from_P0(P0_kPa_try)
            T0_try = refpropm('T','P',P0_kPa_try,'H',hJpkg, fluid);
            a_try  = refpropm('W','T',T0_try,'P',P0_kPa_try, fluid);
            M_try  = refpropm('M','T',T0_try,'P',P0_kPa_try, fluid);
            R_try  = 8314.462618 / M_try;
            gamma_try = (a_try^2)/(R_try*T0_try);
            G_try = mass_flux_isentropic(P0_kPa_try, T0_try, Pd_kPa_in, gamma_try, R_try);
            md = Cd * A * G_try;
        end
    end
    function mdot_tap = compute_tapoff_mdot(Sin, P0_f_kPa_in, T0_f_in, gamma_f_in, R_f_in, Pd_tap_kPa_in)
        mdot_tap = 0;
        if ~isfield(Sin,'Fuel_Tapoff_Selector'), return; end
        if ~strcmpi(Sin.Fuel_Tapoff_Selector,'Post-Reg'), return; end
        if ~isfield(Sin,'Fuel_Tapoff_D1_mm') || ~isfinite_num(Sin.Fuel_Tapoff_D1_mm), return; end
        if ~isfield(Sin,'Fuel_Tapoff_Cd')   || ~isfinite_num(Sin.Fuel_Tapoff_Cd),   return; end
        A_tap = area_from_d_mm(Sin.Fuel_Tapoff_D1_mm);
        G_tap = mass_flux_isentropic(P0_f_kPa_in, T0_f_in, Pd_tap_kPa_in, gamma_f_in, R_f_in);
        mdot_tap = Sin.Fuel_Tapoff_Cd * A_tap * G_tap;
    end
end
