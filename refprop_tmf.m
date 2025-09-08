function [Gstar, mdot] = refprop_tmf(P0_kPa, T0, fluid, CdA_m2)
%REFPROP_TMF  Critical (choked) mass flux G* [kg/(s·m^2)] and optional mdot
%   [Gstar, mdot] = refprop_tmf(P0_kPa, T0, fluid, CdA_m2)
%
% Inputs:
%   P0_kPa   - upstream total (stagnation) pressure, kPa (absolute)
%   T0       - upstream total temperature, K
%   fluid    - REFPROP fluid string, e.g. 'OXYGEN'
%   CdA_m2   - (optional) effective area = C_d * A, in m^2
%
% Outputs:
%   Gstar    - choked mass flux [kg/(s·m^2)]
%   mdot     - (optional) mass flow rate [kg/s]; NaN if CdA_m2 not given
%
% Notes:
%   - Uses REFPROP to get speed of sound (W) and molar mass (M), then
%     gamma and R via a^2 = gamma*R*T.
%   - If you need subcritical (unchoked) mass flux, use your isentropic MF
%     function; this helper is for the choked limit.

    if isempty(which('refpropm'))
        error('REFPROP not found on MATLAB path.');
    end
    if nargin < 4
        CdA_m2 = NaN;  % no mdot if not provided
    end
    if isempty(T0) || isnan(T0)
        error('T0 must be provided (K).');
    end

    % Thermo at (P0,T0)
    a = refpropm('W','T',T0,'P',P0_kPa,fluid);   % m/s
    M = refpropm('M','T',T0,'P',P0_kPa,fluid);   % kg/kmol (numeric same as g/mol)
    R = 8314.462618 / M;                         % J/(kg·K)
    gamma = (a^2)/(R*T0);

    % Critical mass flux
    P0_Pa = P0_kPa*1000;
    Gstar = P0_Pa * sqrt(gamma/(R*T0)) * (2/(gamma+1))^((gamma+1)/(2*(gamma-1)));

    % Optional mass flow if CdA provided
    if isnan(CdA_m2)
        mdot = NaN;
    else
        mdot = CdA_m2 * Gstar;   % kg/s
    end
end
