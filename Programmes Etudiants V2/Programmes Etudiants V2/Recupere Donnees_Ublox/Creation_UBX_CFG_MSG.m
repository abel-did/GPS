%------------------------------------------------------
%         
%       Fonction d'elaboration du message UBX_CFG_MSG
%       pour l'activer et lui donner un taux d'émission (rate)
%------------------------------------------------------
%  Les données d'entrée sont : 

%           - la classe du message qu'on veut activer
%           - son identifiant
%           - son rate voulu

function messageUBX = Creation_UBX_CFG_MSG(classe,id,rate)

messageUBX = zeros(1,9+2);

% On commence par coller l'en tête standard

messageUBX(1:2) = [181,98];

% Puis la classe et l'identifiant du message

messageUBX(3:4) = [6,1];

% Puis la taille du payload (parce que c'est le message pour ajuster le rate)

messageUBX(5:6) = [3,0];

% Le contenu du payload

messageUBX(7:9) = [classe,id,rate];

% On calcule la checksum

[Chk_A, Chk_B] = UBX_Checksum(messageUBX(3:9));

% On met la check sum en fin de message

messageUBX(10:11) = [Chk_A,Chk_B];

messageUBX = uint8(messageUBX);







