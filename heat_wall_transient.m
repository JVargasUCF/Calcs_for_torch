% heat_wall_transient.m
function res = heat_wall_transient(hw)
Lc = hw.t; 
Bi = hw.h_in*Lc/hw.k;
if Bi < 0.1
    C = hw.rho*hw.cp*hw.t*hw.A;
    R_in = 1/(hw.h_in*hw.A);
    R_cond = hw.t/(hw.k*hw.A);
    R_out = 1/(hw.h_out*hw.A);
    Rtot = R_in + R_cond + R_out;
    tau = C*Rtot;
    T_end = hw.Tg + (hw.Ti - hw.Tg)*exp(-hw.t_run/tau);
    res = struct('Bi',Bi,'Fo',NaN,'T_inner_end',T_end,'T_outer_end',T_end,'q_to_amb',(T_end-hw.Ti)/R_out);
    return
end
Nx = 31; dx = hw.t/(Nx-1);
dt = hw.t_run/400; 
alpha = hw.k/(hw.rho*hw.cp);
r = alpha*dt/(dx^2);
T = hw.Ti*ones(Nx,1);
for n=1:ceil(hw.t_run/dt)
    T_old = T;
    A = diag((1+2*r)*ones(Nx,1)) + diag(-r*ones(Nx-1,1),1) + diag(-r*ones(Nx-1,1),-1);
    b = T_old;
    A(1,1) = 1 + 2*r + 2*r*dx*hw.h_in/hw.k;
    b(1)   = T_old(1) + 2*r*dx*hw.h_in/hw.k*(hw.Tg);
    A(end,end) = 1 + 2*r + 2*r*dx*hw.h_out/hw.k;
    b(end)     = T_old(end) + 2*r*dx*hw.h_out/hw.k*(hw.Ti);
    T = A\b;
end
res.Bi = Bi;
res.Fo = alpha*hw.t_run/(hw.t^2);
res.T_inner_end = T(1);
res.T_outer_end = T(end);
res.q_to_amb = hw.h_out*hw.A*(T(end)-hw.Ti);
end
