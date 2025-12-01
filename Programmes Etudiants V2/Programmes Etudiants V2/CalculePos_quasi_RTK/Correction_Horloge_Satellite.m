function corPR = Correction_Horloge_Satellite(t, Ephem)
	F = -4.442807633e-10;
	mu = 3.986005e14;
	a = Ephem(17)^2;
    ecc = Ephem(3);
    af0 = Ephem(18);
    af1 = Ephem(19);
    af2 = Ephem(20);
    toe = Ephem(2);
    toc = Ephem(21);
    deltan = Ephem(10);
    M0 = Ephem(7);
    
    n0 = (mu / a^3)^0.5;

    N = n0 + deltan;

	tk = t - toe;

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

    
	corPR = af0 + af1*(t-toc) + af2*(t-toc)^2 + F*ecc*a^0.5*sin(Ek);
	end