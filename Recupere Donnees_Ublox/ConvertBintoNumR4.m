%------------------------------------------------------
%         
%           Fonction conversion binaire en nombre
%
%------------------------------------------------------

% Fonction qui convertit une chaine de caractères en format binaire en
% nombre flottant à double précision selon la norme IEEE 754


function [NombEndec] = ConvertBintoNumR4(ValBin)

NombEndec = 0;

signe = 1;

% On récupère d'abord le signe 

if ValBin(1) == 1

    signe = -1;
    
end

% On récupère l'exposant

Exposant = bin2dec(ValBin(2:9));

Decalage = Exposant-127;

% Si le décalage est positif 

NombEndec = 1*2^Decalage;   % le premier bit qui n'est pas écrit mais est toujours au début de la mantisse (partie après la virgule)
for i =10:32

    NombEndec = NombEndec+ bin2dec(ValBin(i))*2^(-1*(i-10)+Decalage-1);

end

NombEndec = NombEndec*signe;
