% flow_decay_steady.m - flow steadiness from measured head decay

% fluid (water)
rho = 1000;     % density [kg/m^3]
mu  = 1e-3;     % viscosity [Pa*s]
g   = 9.81;     % [m/s^2]

% geometry
A = 3.0e-5;     % reservoir area [m^2] (P1000 tip, d ~ 6.2 mm)
w = 4e-3;       % channel width [m]
h = 75e-6;      % channel height [m]

% measured decay (N = 3)
dh_at = 0.015;      % head at measurement [m]
dhdt  = 4.23e-7;    % decay rate [m/s]

% operating point
dH0 = 0.02;         % initial head [m]
t_w = [60, 300];    % imaging windows [s]

%% tau and velocity change
tau     = dh_at / dhdt;             % [s]
dv_frac = 1 - exp(-t_w ./ tau);

%% operating point
R   = 2*tau*rho*g / A;      % resistance [Pa*s/m^3]
Q0  = rho*g*dH0 / R;        % flow rate [m^3/s]
v0  = Q0 / (w*h);           % mean velocity [m/s]
shr = 6*v0 / h;             % wall shear rate [1/s]
Re  = rho*v0*(2*h) / mu;    % Reynolds, D_h = 2h

fprintf('tau        = %.2f hr\n',        tau/3600);
fprintf('R          = %.2e Pa*s/m^3\n',  R);
fprintf('Q0         = %.2f uL/min\n',    Q0*1e9*60);
fprintf('v0         = %.1f um/s\n',      v0*1e6);
fprintf('wall shear = %.1f 1/s\n',       shr);
fprintf('Re         = %.1e\n',           Re);
for k = 1:numel(t_w)
    fprintf('dv/v0 at %5d s = %.2f %%\n', t_w(k), 100*dv_frac(k));
end

%% plots
figure;

% full decay
subplot(1,2,1); hold on; box on; grid on;
t_tot = linspace(0, 5*tau, 500);
plot(t_tot/3600, exp(-t_tot ./ tau), 'LineWidth', 1.6);
xline(tau/3600, '--', '\tau', 'Color', [.5 .5 .5]);
xlabel('time (hr)');
ylabel('normalized velocity v/v_0');
title('Full decay');

% 5 min window
subplot(1,2,2); hold on; box on; grid on;
t5 = linspace(0, 300, 500);
plot(t5, exp(-t5 ./ tau), 'LineWidth', 1.6);
plot(t_w, exp(-t_w ./ tau), 'ko', 'MarkerFaceColor', 'k');
for k = 1:numel(t_w)
    text(t_w(k), exp(-t_w(k)/tau), sprintf('  %.3f', exp(-t_w(k)/tau)), ...
        'VerticalAlignment', 'top', 'FontSize', 9);
end
ylim([0.99 1.001]);
xlabel('time (s)');
ylabel('normalized velocity v/v_0');
title('Over a 5-min acquisition');