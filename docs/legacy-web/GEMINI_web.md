# GEMINI.md — Odyssey Project Guide

## 1. Project Identity & Scope
- **Title**: **ODYSSEY (오디세이: 귀환의 항해)**
- **Standalone Project**: Completely independent from any existing Godot projects (such as the Seoul Street Godot project).
- **Tech Stack**: TypeScript + Three.js + Vite (Browser-first; desktop packaging evaluated post-MVP).
- **Key Documents**:
  - [`SPEC.md`](./SPEC.md): Game design, combat mechanics, and visual/architectural rules.
  - [`PLAN.md`](./PLAN.md): Milestone roadmap starting with the combined M1+M2 playable combat prototype.

## 2. Core Design & Engineering Rules
1. **Strict Separation of Combat Logic and Visuals**:
   - `src/combat/` and `src/entities/` contain pure game state, timers, hitboxes, and AI state machines (`Windup/Telegraph -> Active -> Recovery`) without coupling to specific image assets.
   - `src/rendering/` renders entities using procedural 2D silhouette sprites and clear geometric indicators now, allowing drop-in image sprite replacements later.
2. **Controls & Combat Rules**:
   - **Movement**: Screen-space `WASD` (`W` = up/-Z, `S` = down/+Z, `A` = left/-X, `D` = right/+X).
   - **Aiming**: Always toward the mouse cursor projected onto the ground plane (`Y = 0`).
   - **Primary Weapon (`Left Click`)**: Fixed to **Bronze Spear (청동 창)** with a 3-hit combo.
   - **Secondary Weapon (`Right Click Hold`)**: **Bow of Eurytus (강궁)** with unlimited arrows, reduced movement speed while charging, dash-cancel support (`Space`), full-charge piercing (`Power Shot`), and boss weak-point sniping.
   - **Shield Parry (`Q`)**: Reflects enemy projectiles toward the cursor and staggers melee attackers.
   - **Divine Power (`E`)**: Reserved slot for M3 Olympian Boon active skill.
3. **Readability & Boss Gimmick Learning**:
   - Strong enemy attacks must display both a **ground telegraph indicator** and a **body wind-up motion**.
   - Boss mechanics must be naturally introduced in pre-boss rooms through weaker enemies or interactive contraptions.
4. **Performance Telemetry**:
   - Target 60FPS and expose real-time measured FPS and frame time (`ms`) on screen.
