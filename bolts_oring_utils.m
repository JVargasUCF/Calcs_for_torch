% bolts_oring_utils.m
function T = torque_from_preload(K, F, D)
    T = K*F*D;
end
function F = preload_from_proof(S_p, d_nom)
    At = pi/4*(0.75*d_nom)^2;
    F = 0.7*S_p*At;
end
function [T_gland] = oring_gland_temp(T_gas, T_amb, h_in, h_out, k, t, A)
    R_in = 1/(h_in*A);
    R_cond = t/(k*A);
    R_out = 1/(h_out*A);
    T_gland = (R_out*T_gas + (R_in+R_cond)*T_amb)/(R_in+R_cond+R_out);
end
