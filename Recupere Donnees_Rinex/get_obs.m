function obs = get_obs(observationfile, nsat)
%get_obs  
%         are reshaped into a matrix with 21 rows and
%         as many columns as there are ephemerides.

%         Typical call obs = get_obs('rinex.dat', 32)

%Kai Borre 10-10-96
%Copyright (c) by Kai Borre
%$Revision: 1.0 $  $Date: 1997/09/26  $

fide = fopen(observationfile);
[Tabdonnees, count] = fread(fide, Inf, 'double');
noligne = count/(nsat*7+1);
obs = reshape(Tabdonnees, noligne, nsat*7+1);
%%%%%%%% end get_obs.m %%%%%%%%%%%%%%%%%%%%%
