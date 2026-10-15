# CONQUER — System Requirements Specification (SRS)
> "CONQUER — Own Your World."

## 1. Introduction
CONQUER is a real-world multiplayer territory conquest application powered by GPS walking and running tracking. The system translates physical movement into real geographic territory by detecting closed GPS movement loops on an interactive map.

---

## 2. Functional Modules (M1 - M18)

| Module ID | Module Name | Description |
| :--- | :--- | :--- |
| **M1** | **Authentication Module** | Handles Email/Password, Firebase Auth, JWT session management, and player credentials. |
| **M2** | **User Profile Module** | Manages player public username, avatar, level titles, XP, coins balance, total territory, and streak flame. |
| **M3** | **Map Module** | Interactive Google Maps / Leaflet map rendering current position, active route polyline, owned player polygons, and enemy territory overlays. |
| **M4** | **GPS Tracking Module** | Samples real-time GPS coordinates (`lat`, `lng`, `speed`, `timestamp`, `accuracy`) during active conquest sessions. |
| **M5** | **Activity Detection Module** | Infers activity classification (Walking: 0-8 km/h, Running: 8-20 km/h, Suspicious: >20 km/h). |
| **M6** | **Loop Detection Module** | Enforces core game rules: total distance $\ge 100\text{m}$, return tolerance $\le 10\text{m}$ to start coordinate. |
| **M7** | **Territory Generation Module** | Converts valid closed GeoJSON LineStrings into closed GeoJSON Polygons and calculates geodesic area ($\text{km}^2$). |
| **M8** | **Territory Ownership Module** | Persists active territories in MongoDB with `2dsphere` spatial indexing. |
| **M9** | **Territory Capture Module** | Executes Turf.js geometric difference ($T_{\text{enemy, new}} = T_{\text{enemy, old}} \setminus P_{\text{new}}$) to slice and award overlapping land to attackers. |
| **M10** | **Anti-Cheat Module** | Computes Trust Score (0-100%) based on speed caps, instantaneous jump detection, and mock location flags. |
| **M11** | **Fitness / Steps Module** | Integrates Android Health Connect to sync step count, walking sessions, and exercise routes. |
| **M12** | **Gamification Module** | Calculates XP gains, coin rewards, daily streak increments, and level titles (Level 1 - 10). |
| **M13** | **Achievement Module** | Tracks threshold progression for achievements (First Explorer, Pathfinder, Land Master, 7-Day Streak). |
| **M14** | **Friends Module** | Friend search, requests, profile inspection, and territory empire comparison. |
| **M15** | **Leaderboard Module** | Global, Nearby, and Friends rankings ordered by total currently owned area ($\text{km}^2$). |
| **M16** | **Notification Module** | Dispatches FCM push notifications for territory attacks ("🚨 Rahul captured 0.32 km² of your territory!"). |
| **M17** | **Exploration Module** | Tracks discovered geographic map tiles and calculates percentage of city explored. |
| **M18** | **Admin Module** | Web console to adjust game rule parameters (`minLoopDistance`, `returnTolerance`), audit fraud flags, and manage restricted zones. |

---

## 3. Real-World Territory Conquest Algorithm Flow

```
[START] ──► Record GPS (P1..Pn) ──► Speed Check (<20 km/h) ──► Loop Check (>=100m, <=10m return)
                                                                       │
                                                                       ▼
[UPDATE MAP & AWARD XP] ◄── [MONGODB 2DSPHERE] ◄── Spatial Difference ◄── GeoJSON Polygon
```
