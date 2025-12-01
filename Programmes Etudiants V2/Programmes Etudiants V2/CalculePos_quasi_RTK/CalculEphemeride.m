%--------------------------------------------------------------------------
% Fonction pour calculer les coordonnées des satellites à partir des
% éphémérides et renvoyer la correction à appliquer à la pseudodistance
%
%--------------------------------------------------------------------------

function [Xs, Ys, Zs] = CalculEphemeride(t_GPS,Ephem)

%Pi = 3.1415926535898;  % on définit Pi avec le bon nombre de décimales

mu = 398600500000000;
omegadote = 7.2921151467 * 10^-5;

toe = Ephem(2);
ecc = Ephem(3);
i0 = Ephem(4);
omega0 = Ephem(5);
omega = Ephem(6);
M0 = Ephem(7);
idot = Ephem(8);
omegadot = Ephem(9);
deltan = Ephem(10);
cuc = Ephem(11);
cus = Ephem(12);
crc = Ephem(13);
crs = Ephem(14);
cic = Ephem(15);
cis = Ephem(16);
a = Ephem(17)^2;


%Calcul de la position des satellites
n0 = (mu / a^3)^0.5;

N = n0 + deltan;

tk = t_GPS - toe;       

if tk > 302400        %procédure pour les problèmes de transition d'une semaine à l'autre
    tk = tk - 604800;
elseif tk < -302400
    tk = tk + 604800;
end

Mk = M0 + N * tk;
Ek = Mk;
%op = abs(Mk - Ek + ecc * sin(Ek));

while abs(Mk - Ek + ecc * sin(Ek)) > 10^-12   %boucle de calcul de Ek

    Ek = Ek - (Ek - ecc * sin(Ek) - Mk) / (1 - ecc * cos(Ek));
    %op = abs(Mk - Ek + ecc * sin(Ek));
end


%-------------------------- théoriquement rien d'autre à faire ---------------

sinusVk = (sin(Ek) * (1 - ecc^2)^0.5) / (1 - ecc * cos(Ek));

cosinusVk = (cos(Ek) - ecc) / (1 - ecc * cos(Ek));
                                                                                                                                             
Phik = atan2(sinusVk, cosinusVk) + omega;

deltaPhik = cus * sin(2 * Phik) + cuc * cos(2 * Phik);
deltark = crs * sin(2 * Phik) + crc * cos(2 * Phik);
deltaik = cis * sin(2 * Phik) + cic * cos(2 * Phik);

uk = Phik + deltaPhik;
rk = a * (1 - ecc * cos(Ek)) + deltark;
ik = i0 + idot * tk + deltaik;
Omegak = omega0 + (omegadot - omegadote) * tk - omegadote * toe;
xp = rk * cos(uk);
yp = rk * sin(uk);

Xs = xp * cos(Omegak) - yp * cos(ik) * sin(Omegak);
Ys = xp * sin(Omegak) + yp * cos(ik) * cos(Omegak);
Zs = yp * sin(ik);


