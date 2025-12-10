%------------------------------------------------------
%         
%           Fonction conversion binaire en nombre
%           pour les données GPS
%
%------------------------------------------------------

% Fonction qui convertit une chaine de caractères binaires en nombre décimal

% Données d'entrée : 

%        - Valbin : valeur de la chaîne de caractères
%        - Scale factor en puissance de 2 (applicable au bit de poids
%        faible)
%        - signeON : indique si le nombre est signé ou pas



function [NombEndec] = ConvertBintoNumMesNavGPS(ValBin,ScaleF,signeON)


% On convertit le tableau de caratères en tableau de nombres
ValBin01 = zeros(1,length(ValBin));
for i=1:length(ValBin)    
    if ValBin(i) == '1'
        ValBin01(i) = 1;
    end
end

% On demande si le nombre est signé

if signeON == 1      
    numbit = length(ValBin01)-1;  % nombre de bits hors signe   

    % Si le nombre est signé, on demande s'il est négatif

    if ValBin01(1) == 1

        % S'il est négatif, il faut complémenter les bits avant le calcul

        Cpm = mod(ValBin01(2:numbit+1) + 1,2);

        % On ajoute 1

        i=numbit;
        while i > 0 && Cpm(i) == 1
            Cpm(i) = 0;
            i=i-1;
        end

        if i > 0
            Cpm(i) = 1;
        end

        % On remet la valeur une fois les opérations terminées

        ValBin01 = Cpm;

        % On convertit en tenant compte du scale factor
        NombEndec = 0;
        for i=1:numbit
            NombEndec = ValBin01(i)*2^(ScaleF+numbit-i)+NombEndec;
        end

        if NombEndec == 0   % Si le nombre à envoyer est nul, cela signifie qu'on est au bout de la représentation en complément à 2

            NombEndec = 2^(ScaleF+numbit);

        end

        % Le nombre est signé négatif

        NombEndec = -1*NombEndec;

    else

        % Le nombre est positif, on passe directement à la conversion

        ValBin01 = ValBin01(2:numbit+1);

        NombEndec = 0;
        for i=1:numbit
            NombEndec = ValBin01(i)*2^(ScaleF+numbit-i)+NombEndec;
        end

    end

else

    % Le nombre n'est pas signé, tous les bits comptent

    numbit = length(ValBin01);

    % Convertit de suite
    NombEndec = 0;
    for i=1:numbit
        NombEndec = ValBin01(i)*2^(ScaleF+numbit-i)+NombEndec;
    end

end


