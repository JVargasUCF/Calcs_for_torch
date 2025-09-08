% torch_combustion_quicklook.m
function out = torch_combustion_quicklook(in)
% Compute torch combustion properties using Cantera if available.
% See header in file for usage.
OF  = in.mdot_O2 / in.mdot_H2;
phi = 8.0 / OF; % stoich O/F ~ 8

Pc = in.Pc_guess; % placeholder; refine with nozzle model if desired

try
    gas = Solution('gri30.yaml');
    MW_H2 = 2.01588e-3;  MW_O2 = 31.998e-3;
    nH2 = in.mdot_H2/MW_H2; nO2 = in.mdot_O2/MW_O2;
    set(gas,'T',300,'P',Pc,'X',sprintf('H2:%g,O2:%g',nH2,nO2));
    equilibrate(gas,'HP');
    Tad = temperature(gas);
    gamma = cp_mass(gas)/cv_mass(gas);
    R = gasconstant/MW(gas);
catch
    Tad = 2800; gamma = 1.22; R = 370;
end

Me = 1.0;
a  = sqrt(gamma*R*Tad);
Ue = Me*a;
out = struct('Pc',Pc,'Tad',Tad,'gamma',gamma,'R',R,'a',a,'Ue',Ue,'Me',Me,'phi',phi,'OF',OF);
end
