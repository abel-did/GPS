%% Q6 + Q9 : Positionnement GPS avec élévation minimale
% Paramètres de simulation

clear all; close all; clc;

% Constantes
R_TERRE = 6400e3;      % Rayon de la Terre en mètres
R_SAT = 20200e3;       % Distance des satellites depuis le centre de la Terre
H_RECEPTEUR = 1.3;     % Altitude du récepteur au-dessus de la surface
N_SATELLITES = 4;      % Nombre de satellites
c = 299792458;         % Vitesse de la lumière (m/s)

%% Position du récepteur
lat_rec = deg2rad(45);  
lon_rec = deg2rad(0);   

% Position du récepteur en ECEF (Earth-Centered Earth-Fixed)
x_rec = (R_TERRE + H_RECEPTEUR) * cos(lat_rec) * cos(lon_rec);
y_rec = (R_TERRE + H_RECEPTEUR) * cos(lat_rec) * sin(lon_rec);
z_rec = (R_TERRE + H_RECEPTEUR) * sin(lat_rec);
pos_recepteur = [x_rec; y_rec; z_rec];

%% Génération RIGOUREUSE des positions satellites

fprintf('===== GÉNÉRATION DES SATELLITES =====\n');

% Configuration FIXE pour garantir la convergence
fprintf('Utilisation d''une configuration fixe bien répartie\n\n');

% Satellites aux 4 points cardinaux avec élévation moyenne
azimuths_deg = [0, 90, 180, 270];     % N, E, S, O
elevations_deg = [45, 45, 45, 60];    % Élévations moyennes

azimuths = deg2rad(azimuths_deg);
elevations = deg2rad(elevations_deg);

fprintf('Configuration fixe :\n');
for i = 1:N_SATELLITES
    fprintf('  Satellite %d: Az = %.1f°, El = %.1f°\n', ...
            i, azimuths_deg(i), elevations_deg(i));
end
fprintf('\n');

% Initialisation
positions_satellites = zeros(3, N_SATELLITES);

% MÉTHODE DIRECTE : Coordonnées sphériques GLOBALES (ECEF)
for i = 1:N_SATELLITES
    % Calculer latitude et longitude du satellite dans le référentiel ECEF
    % en tenant compte de l'élévation et azimut LOCAL du récepteur
    
    % Vecteur unitaire dans le référentiel local (ENU)
    % E = Est, N = Nord, U = Up (vertical)
    E_local = sin(azimuths(i)) * cos(elevations(i));
    N_local = cos(azimuths(i)) * cos(elevations(i));
    U_local = sin(elevations(i));
    
    % Matrice de rotation ENU -> ECEF
    % Dépend de la latitude/longitude du récepteur
    sin_lat = sin(lat_rec);
    cos_lat = cos(lat_rec);
    sin_lon = sin(lon_rec);
    cos_lon = cos(lon_rec);
    
    R_enu_to_ecef = [-sin_lon,           -sin_lat*cos_lon,  cos_lat*cos_lon;
                      cos_lon,           -sin_lat*sin_lon,  cos_lat*sin_lon;
                      0,                  cos_lat,           sin_lat];
    
    % Direction vers le satellite dans ECEF (vecteur unitaire)
    dir_ecef = R_enu_to_ecef * [E_local; N_local; U_local];
    
    % Position du satellite = position récepteur + R_SAT * direction
    % (approximation : on place le satellite à R_SAT du centre de la Terre)
    % Méthode correcte : normaliser puis mettre à la distance R_SAT
    
    % Position approximative
    pos_temp = pos_recepteur + dir_ecef * (R_SAT - norm(pos_recepteur));
    
    % Normaliser pour avoir exactement R_SAT
    pos_sat = pos_temp / norm(pos_temp) * R_SAT;
    
    positions_satellites(:, i) = pos_sat;
end

% Vérifications
fprintf('Positions des satellites (ECEF):\n');
for i = 1:N_SATELLITES
    dist_centre = norm(positions_satellites(:,i));
    erreur_dist = abs(dist_centre - R_SAT);
    
    fprintf('Satellite %d:\n', i);
    fprintf('  X = %.2f m\n', positions_satellites(1, i));
    fprintf('  Y = %.2f m\n', positions_satellites(2, i));
    fprintf('  Z = %.2f m\n', positions_satellites(3, i));
    fprintf('  Distance centre = %.2f km (erreur = %.3f m)\n\n', ...
            dist_centre/1000, erreur_dist);
end

% Vérifier la visibilité (produit scalaire > 0)
fprintf('Vérification visibilité:\n');
for i = 1:N_SATELLITES
    vect_sat = positions_satellites(:,i) - pos_recepteur;
    normale_locale = pos_recepteur / norm(pos_recepteur);
    prod_scal = dot(vect_sat, normale_locale);
    
    if prod_scal > 0
        fprintf('  Satellite %d: VISIBLE (prod. scal. = %.2e)\n', i, prod_scal);
    else
        warning('  Satellite %d: SOUS L''HORIZON !', i);
    end
end
fprintf('\n');

%% Affichage des positions
fprintf('===== POSITIONS DES SATELLITES =====\n\n');
fprintf('Position du récepteur (ECEF):\n');
fprintf('  X = %.2f m\n', pos_recepteur(1));
fprintf('  Y = %.2f m\n', pos_recepteur(2));
fprintf('  Z = %.2f m\n\n', pos_recepteur(3));

fprintf('Coordonnées locales (aléatoires avec contrainte):\n');
for i = 1:N_SATELLITES
    fprintf('Satellite %d: Az = %.1f°, El = %.1f°\n', ...
            i, rad2deg(azimuths(i)), rad2deg(elevations(i)));
end

fprintf('\nPositions des satellites (ECEF):\n');
for i = 1:N_SATELLITES
    fprintf('Satellite %d:\n', i);
    fprintf('  X = %.2f m\n', positions_satellites(1, i));
    fprintf('  Y = %.2f m\n', positions_satellites(2, i));
    fprintf('  Z = %.2f m\n', positions_satellites(3, i));
    fprintf('  Distance du centre = %.2f km\n\n', ...
            norm(positions_satellites(:, i))/1000);
end

%% ========== CALCUL DES PSEUDODISTANCES MESURÉES ==========

% Position vraie du récepteur (que l'on va chercher à retrouver)
pos_recepteur_vrai = pos_recepteur;
t_u_vrai = 0;  % Pas de biais d'horloge en simulation parfaite

% Calcul des pseudodistances "mesurées" (simulation)
rho_mesure = zeros(N_SATELLITES, 1);

fprintf('\n===== PSEUDODISTANCES MESURÉES =====\n');
for j = 1:N_SATELLITES
    % Distance géométrique vraie satellite-récepteur
    distance_geom = norm(positions_satellites(:,j) - pos_recepteur_vrai);
    
    % Pseudodistance = distance + c*biais_horloge
    rho_mesure(j) = distance_geom + c * t_u_vrai;
    
    fprintf('ρ%d = %.3f km\n', j, rho_mesure(j)/1000);
end

%% ========== ALGORITHME ITÉRATIF DE POSITIONNEMENT ==========

fprintf('\n===== ALGORITHME ITÉRATIF =====\n');

% INITIALISATION AMÉLIORÉE : Surface de la Terre sous le récepteur
% Au lieu de (0,0,0), on initialise à la surface terrestre
x_hat = R_TERRE * cos(lat_rec) * cos(lon_rec);
y_hat = R_TERRE * cos(lat_rec) * sin(lon_rec);
z_hat = R_TERRE * sin(lat_rec);
t_hat = 0;

fprintf('Position initiale (surface Terre) :\n');
fprintf('  X = %.2f m, Y = %.2f m, Z = %.2f m\n', x_hat, y_hat, z_hat);
fprintf('  Distance au centre : %.2f km\n', norm([x_hat; y_hat; z_hat])/1000);
fprintf('  Distance à la position vraie : %.2f m\n\n', ...
        norm([x_hat; y_hat; z_hat] - pos_recepteur));

% Paramètres de convergence
max_iterations = 10;
tolerance = 1e-6;  % Critère d'arrêt en mètres

% Pour suivre la convergence
historique_position = [];
historique_erreur = [];

%% Boucle itérative (Newton-Raphson)

for iteration = 1:max_iterations
    
    fprintf('\n--- Itération %d ---\n', iteration);
    
    % === A) Calculer les pseudodistances approximatives ρ̂j ===
    rho_hat = zeros(N_SATELLITES, 1);
    r_hat = zeros(N_SATELLITES, 1);
    
    for j = 1:N_SATELLITES
        % Distance approximative r̂j (équation 2.28)
        dx = positions_satellites(1,j) - x_hat;
        dy = positions_satellites(2,j) - y_hat;
        dz = positions_satellites(3,j) - z_hat;
        r_hat(j) = sqrt(dx^2 + dy^2 + dz^2);
        
        % Pseudodistance approximative ρ̂j (équation 2.25)
        rho_hat(j) = r_hat(j) + c * t_hat;
    end
    
% === B) Calculer les différences Δρj ===
Delta_rho = rho_hat - rho_mesure;  
fprintf('Max |Δρ| = %.6f m\n', max(abs(Delta_rho)));
    
    % === C) Construire la matrice H (géométrie) ===
    H = zeros(N_SATELLITES, 4);
    
    for j = 1:N_SATELLITES
        % Cosinus directeurs (équation 2.31)
        a_xj = (positions_satellites(1,j) - x_hat) / r_hat(j);
        a_yj = (positions_satellites(2,j) - y_hat) / r_hat(j);
        a_zj = (positions_satellites(3,j) - z_hat) / r_hat(j);
        
        H(j,:) = [a_xj, a_yj, a_zj, 1];
    end
    
    % === D) Vérifier que H est inversible ===
    rang_H = rank(H);
    cond_H = cond(H);
    
    fprintf('Rang de H : %d, Conditionnement : %.2e\n', rang_H, cond_H);
    
    if rang_H < 4
        warning('Matrice H non inversible (rang = %d) !', rang_H);
        fprintf('Mauvaise géométrie des satellites.\n');
        break;
    end
    
    if cond_H > 1e10
        warning('Matrice H mal conditionnée (cond = %.2e)', cond_H);
    end
    
    % === E) Résoudre le système linéaire Δx = H⁻¹·Δρ ===
    Delta_x = H \ Delta_rho;  % (équation 2.34)
    
    % === F) Mettre à jour la solution ===
    x_hat = x_hat + Delta_x(1);
    y_hat = y_hat + Delta_x(2);
    z_hat = z_hat + Delta_x(3);
    t_hat = t_hat + Delta_x(4);
    
    % Sauvegarder l'historique
    pos_estimee = [x_hat; y_hat; z_hat];
    historique_position = [historique_position, pos_estimee];
    
    % === G) Calculer l'erreur de position ===
    erreur_correction = norm(Delta_x(1:3));
    erreur_vs_vrai = norm(pos_estimee - pos_recepteur_vrai);
    historique_erreur = [historique_erreur; erreur_vs_vrai];
    
    fprintf('Correction appliquée : %.9f m\n', erreur_correction);
    fprintf('Erreur vs position vraie : %.9f m\n', erreur_vs_vrai);
    fprintf('Position estimée : X=%.2f, Y=%.2f, Z=%.2f m\n', ...
            x_hat, y_hat, z_hat);
    
    % === H) Test de convergence ===
    if erreur_correction < tolerance
        fprintf('\nCONVERGENCE atteinte après %d itérations !\n', iteration);
        break;
    end
    
    if iteration == max_iterations
        fprintf('\nNombre max d''itérations atteint.\n');
    end
end

%% ========== RÉSULTATS FINAUX ==========

fprintf('\n========== RÉSULTATS FINAUX ==========\n');

pos_calculee = [x_hat; y_hat; z_hat];

fprintf('\nPosition CALCULÉE (ECEF):\n');
fprintf('  X = %.2f m\n', x_hat);
fprintf('  Y = %.2f m\n', y_hat);
fprintf('  Z = %.2f m\n', z_hat);
fprintf('  Distance du centre : %.2f km\n', norm(pos_calculee)/1000);

fprintf('\nPosition VRAIE (ECEF):\n');
fprintf('  X = %.2f m\n', pos_recepteur_vrai(1));
fprintf('  Y = %.2f m\n', pos_recepteur_vrai(2));
fprintf('  Z = %.2f m\n', pos_recepteur_vrai(3));

fprintf('\nBiais d''horloge estimé:\n');
fprintf('  t_u = %.12f s\n', t_hat);
fprintf('  c·t_u = %.6f m\n', c*t_hat);

erreur_finale = norm(pos_calculee - pos_recepteur_vrai);
fprintf('\nERREUR FINALE DE POSITIONNEMENT : %.9f m\n', erreur_finale);

if erreur_finale < 1e-3
    fprintf('SUCCESS : Précision millimétrique !\n');
elseif erreur_finale < 1
    fprintf('SUCCESS : Précision centimétrique !\n');
else
    fprintf('ATTENTION : Erreur importante.\n');
end

%% ========== GRAPHIQUES ==========

% Figure 1 : Visualisation 3D des satellites
figure('Position', [50, 100, 900, 900]);

% Sphère terrestre
[x_terre, y_terre, z_terre] = sphere(50);
x_terre = x_terre * R_TERRE;
y_terre = y_terre * R_TERRE;
z_terre = z_terre * R_TERRE;

surf(x_terre, y_terre, z_terre, 'FaceColor', [0.3 0.5 0.8], ...
     'FaceAlpha', 0.4, 'EdgeColor', 'none');
hold on;

% Récepteur
plot3(pos_recepteur(1), pos_recepteur(2), pos_recepteur(3), ...
      'ro', 'MarkerSize', 12, 'MarkerFaceColor', 'r', ...
      'DisplayName', 'Récepteur');

% Satellites
plot3(positions_satellites(1, :), positions_satellites(2, :), ...
      positions_satellites(3, :), 'gs', 'MarkerSize', 15, ...
      'MarkerFaceColor', 'g', 'LineWidth', 2, ...
      'DisplayName', 'Satellites GPS');

% Lignes de visée
for i = 1:N_SATELLITES
    plot3([pos_recepteur(1), positions_satellites(1, i)], ...
          [pos_recepteur(2), positions_satellites(2, i)], ...
          [pos_recepteur(3), positions_satellites(3, i)], ...
          'k--', 'LineWidth', 1, 'HandleVisibility', 'off');
    
    text(positions_satellites(1, i)*1.02, ...
         positions_satellites(2, i)*1.02, ...
         positions_satellites(3, i)*1.02, ...
         sprintf('S%d\n%.0f°', i, rad2deg(elevations(i))), ...
         'FontSize', 10, 'FontWeight', 'bold', 'Color', 'green');
end

axis equal;
grid on;
xlabel('X (m)', 'FontSize', 12);
ylabel('Y (m)', 'FontSize', 12);
zlabel('Z (m)', 'FontSize', 12);
title('Configuration des satellites GPS', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'best', 'FontSize', 10);
view(45, 30);
rotate3d on;
hold off;

% Figure 2 : Convergence
figure('Position', [1000, 100, 1200, 500]);

% Graphique 1 : Erreur vs itération
subplot(1,2,1);
semilogy(1:length(historique_erreur), historique_erreur, 'o-', ...
         'LineWidth', 2, 'MarkerSize', 8, 'Color', [0.8 0.2 0.2]);
grid on;
xlabel('Itération', 'FontSize', 12);
ylabel('Erreur de position (m)', 'FontSize', 12);
title('Convergence de l''algorithme', 'FontSize', 14, 'FontWeight', 'bold');
xlim([1, length(historique_erreur)]);

% Graphique 2 : Trajectoire 3D
subplot(1,2,2);
plot3(historique_position(1,:), historique_position(2,:), ...
      historique_position(3,:), 'b-o', 'LineWidth', 2, 'MarkerSize', 8);
hold on;
plot3(pos_recepteur_vrai(1), pos_recepteur_vrai(2), pos_recepteur_vrai(3), ...
      'r*', 'MarkerSize', 20, 'LineWidth', 3);
plot3(0, 0, 0, 'ko', 'MarkerSize', 10, 'MarkerFaceColor', 'k');
grid on;
xlabel('X (m)', 'FontSize', 12);
ylabel('Y (m)', 'FontSize', 12);
zlabel('Z (m)', 'FontSize', 12);
title('Trajectoire de convergence', 'FontSize', 14, 'FontWeight', 'bold');
legend('Itérations', 'Position vraie', 'Centre Terre', 'Location', 'best');
view(45, 30);
hold off;