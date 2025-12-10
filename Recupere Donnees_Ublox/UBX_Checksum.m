%------------------------------------------------------
%         
%           Fonction de calcul des octets de checksum UBX
%
%------------------------------------------------------
%  Les données d'entrée sont : 

% un tableau d'octets sous forme d'entiers non signés correspondant 
% au message à checker mais sans les deux premiers octets du message qui
% correspondent au charactère de synchro 181 et 98 (en decimal)

function [Chk_A, Chk_B] = UBX_Checksum(trame_mess)

Nb_octmessage = length(trame_mess);

Chk_A = 0;
Chk_B = 0;

for i=1:Nb_octmessage
    Chk_A = Chk_A + trame_mess(i);
    
    Chk_B = Chk_A + Chk_B;
    
end

Chk_A = mod(Chk_A,256);
Chk_B = mod(Chk_B,256);



