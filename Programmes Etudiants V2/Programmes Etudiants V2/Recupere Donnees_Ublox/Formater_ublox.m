%--------------------------------------------------------
%         
% Programme de reformatage pour lecture des données ublox
%
%--------------------------------------------------------

% On veut grouper les trames mais on les réorganise de façon à ne pas couper le flux au milieu d'une
% des trames qui nous intéresse (181 98 2 19 ou 181 98 2 21)

% Données d'entrée : 

%        - cpt_fichier : nombre de fichiers, normalement dans le workspace

% Pour garantir le nombre de fichiers attendus :

nombfichiers = fix(t_total/60); % on ne traitera pas plus qu'un nombre entier de minutes.

% On crée les paquets utiles sous forme d'un tableau de nlignes

trames = zeros(nombfichiers+1,80001); % le premier élément du tableau indique sa longueur

for cpt_fichier = 1:nombfichiers

    nomfichier = sprintf("str%.2d.mat", cpt_fichier);    % on récupère le nom du fichier
    load(nomfichier)                                     % on récupère la variable str
    
    cpt_trame = 72000;
    trametrouve = 0;
    % On part de la fin pour vérifier la présence de la dernière trame
    while cpt_trame > 3 && trametrouve == 0
        
        if (str(cpt_trame) == 21 || str(cpt_trame) == 19 ) && str(cpt_trame-1) == 2 && str(cpt_trame-2) == 98 && str(cpt_trame-3) == 181
            trametrouve = 1;

        else
            cpt_trame=cpt_trame-1;
        end
        
    end

    tailletrame = cpt_trame-4;   % on a la taille de la trame qu'on doit mettre, excluant la trame qui nous intéresse et qui ira au début de la suivante
    

    if cpt_fichier == 1 % si on est à la première on n'a pas de trame à ajouter

        trames(cpt_fichier,1:tailletrame+1) = [tailletrame str(1:tailletrame)];

    else                % dans tous les autres cas oui

        trames(cpt_fichier,1:tailletrame+length(restetrame)+1) = [tailletrame+length(restetrame) restetrame str(1:tailletrame)];

    end
    restetrame = str(tailletrame+1:length(str));    % on récupère la trame qui reste pour la suivante

end

% on finalise en complétant avec le dernier reste :

trames(nombfichiers+1,1:length(restetrame)+1) = [ length(restetrame) restetrame];




     



