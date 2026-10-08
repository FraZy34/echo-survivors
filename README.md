# Écho Survivors

Survivor-like (façon Vampire Survivors) réalisé avec **Godot 4.7** en **GDScript**.
Survivez aux vagues, montez en puissance, puis terrassez le boss de chacun des trois niveaux,
avec l'aide de votre **Écho**, un compagnon spectral qui rejoue vos actions avec deux secondes de retard.

Tous les graphismes, effets sonores et musiques sont **créés par le code du projet**
(`tools/generate_assets.gd`) : pixel art dessiné sous forme de grilles et synthèse sonore.

## Lancer le jeu

1. Ouvrir Godot 4.7 (ou plus récent), *Importer*, puis sélectionner `project.godot`.
2. Appuyer sur **F5**. La scène principale est le menu (`scenes/menus/main_menu.tscn`).

## Commandes

| Action | Touches |
| --- | --- |
| Se déplacer | **Z Q S D** (W A S D en QWERTY, touches physiques), **flèches** ou stick gauche |
| Attaquer | automatique : chaque arme tire selon sa recharge |
| Pause | **Échap** ou **P** |
| Choisir une amélioration | clic, flèches + Entrée, ou **1 / 2 / 3** |

## La mécanique centrale : l'Écho

- L'Écho suit **exactement la trajectoire du joueur, décalée de 2 secondes** (la traînée bleue montre où il va passer).
- Chaque attaque du joueur est enregistrée sous forme de paramètres **relatifs** (directions, décalages vers les cibles)
  puis **rejouée 2 s plus tard depuis la position de l'Écho**, à 60 % de puissance.
- Les monstres poursuivent le joueur, donc se retrouvent sur son ancien chemin : bien se placer permet de
  préparer des frappes différées. Un « battement » toutes les 2 s marque la fin de chaque fenêtre rejouée.
- Améliorations dédiées : **Résonance** (+20 % de puissance), **Reflet** (rejoue aussi chaque attaque en miroir),
  **Onde d'écho** (impulsion de dégâts à chaque battement).

## Contenu

- **3 niveaux** avec décors, ennemis, vagues et boss différents :
  - *Forêt d'Automne* (boss à 4:00) : Le Cyclope Ancien ;
  - *Pics Gelés* (boss à 5:00) : Le Grand Yéti, animé ;
  - *Crypte Maudite* (boss à 6:00) : Le Démon Écarlate.
- **7 armes** : Dague, Arc, Haches orbitales, Aura ardente, Bombes, Foudre, Orbes arcaniques (5 niveaux chacune).
- **15 améliorations passives**, dont 3 liées à l'Écho.
- 4 comportements d'ennemis : poursuite (avec vol erratique), charge, tir à distance, boss à 3 motifs
  (salve circulaire, charge, invocation) qui s'enrage sous 50 % de PV.
- Menu principal, sélection de niveau, pause, écran de fin (temps de survie, score), **meilleur score par niveau**
  sauvegardé dans `user://savegame.cfg`, options (volume des effets et de la musique, nombres de dégâts,
  plein écran).
- Animations : cycle de marche du héros, flottement de l'Écho, 2 images par monstre, pose d'attaque
  (charge des brigands, rugissement du Grand Yéti), plus rebond, flash de dégâts et disparition procéduraux.

## Assets faits maison

Le générateur `tools/generate_assets.gd` produit tout le contenu de `assets/` (sauf la police) :

```
godot --headless --path . --script res://tools/generate_assets.gd
```

- `tools/art/sprite_art.gd` : pixel art dessiné à la main sous forme de grilles de caractères
  (une lettre = une couleur de la palette commune). Héros, Écho, 20 monstres et 3 boss avec leurs
  images d'animation, projectiles, gemmes, icônes d'armes et d'améliorations, éléments de décor.
- `tools/art/pixel_canvas.gd` : assemble les planches 16x16, applique les variantes de palette
  (ex. chauve-souris brune, givrée ou vampire) et ajoute automatiquement le contour sombre.
- `tools/art/floor_painter.gd` : tuiles de sol procédurales raccordables (herbe, neige, dalles).
- `tools/audio/synth.gd` et `sound_bank.gd` : synthétiseur (oscillateurs, bruit, enveloppes, écho) qui
  rend les 12 effets sonores et 4 musiques chiptune en boucle (menu, forêt, neige, crypte).
- `assets/sprites/manifest.json` associe chaque nom de sprite à son indice dans la planche.

Pour modifier un sprite : éditer sa grille, relancer le générateur, Godot réimporte les PNG.

## Architecture

```
assets/            Sprites, sons et musiques générés (+ police libre)
resources/         Données éditables dans l'inspecteur (.tres)
  weapons/         WeaponData : stats, progression par niveau, script de comportement
  enemies/         EnemyData  : visuels, stats, scène de comportement
  levels/          LevelData  : décor, vagues (WaveData), boss, courbe de difficulté
  upgrades/        UpgradeData : améliorations passives
  game_database.tres   point d'entrée vers toutes les données
tools/             Générateur d'assets (pixel art + synthèse sonore)
scenes/            actors/ (joueur, Écho, ennemis hérités de enemy.tscn), game/, menus/, ui/
scripts/
  autoload/        GameState (navigation, sauvegarde, entrées), Sfx (pool audio)
  data/            Classes de ressources (WeaponData, EnemyData, WaveData, LevelData...)
  actors/          Player, Companion, Enemy, puis ChargerEnemy, RangedEnemy et BossEnemy qui en héritent
  weapons/         Weapon, puis ProjectileWeapon, OrbitWeapon, AuraWeapon, LobWeapon et StrikeWeapon qui en héritent
  systems/         Arena, EnemyManager, ProjectileManager, PickupManager, WaveSpawner, UpgradeService
  world/           ChunkedFloor (sol infini), EffectsLayer, Projectile, Pickup
  ui/              HUD, panneaux et menus
```

Ajouter du contenu ne demande pas de code : dupliquer un `.tres` d'arme, d'ennemi ou de niveau, le modifier
dans l'inspecteur et le référencer dans `game_database.tres` (ou dans les vagues d'un niveau).

## Performances

Conçu pour plusieurs centaines d'ennemis simultanés (plafond à 450) :

- aucun nœud de physique : ennemis, projectiles et gemmes sont de simples `Sprite2D` mis à jour
  **dans une seule boucle par gestionnaire** (pas de `_process` par entité) ;
- **grille spatiale** (cellules de 32 px) reconstruite à chaque frame pour les collisions et la visée ;
- séparation entre ennemis limitée à 8 voisins et calculée une frame sur deux ;
- **pools** d'ennemis, de projectiles et de gemmes (aucune allocation en régime établi) ;
- au-delà de 260 gemmes au sol, les nouvelles fusionnent avec des gemmes existantes ;
- tous les effets (anneaux, éclairs, particules, nombres de dégâts) sont dessinés par **un seul `_draw()`** ;
- les sprites partagent quelques textures-planches, ce qui permet au moteur de regrouper les appels de rendu ;
- sol infini chargé par **chunks** déterministes, avec quelques chunks par frame au maximum ;
- les ennemis distancés sont recyclés devant le joueur.

Mesure en headless : environ **1,6 ms de logique par frame avec ~180 ennemis**.

## Crédits

- Graphismes, effets sonores et musiques : générés par le code du projet (`tools/`).
- Police : *Pixelify Sans* (SIL Open Font License, voir `assets/fonts/`), en graisse normale pour le texte
  et grasse pour les titres.
