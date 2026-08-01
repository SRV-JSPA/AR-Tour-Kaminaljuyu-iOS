# CLAUDE.md — AR Tour Kaminaljuyú (iOS)

Este archivo documenta la arquitectura real del proyecto para que cualquier sesión de Claude
(o cualquier persona nueva en el equipo) entienda cómo está construido, cómo se deben
comunicar los módulos, y qué partes de la arquitectura propuesta en la tesis todavía no
están completamente implementadas. Está basado en una revisión directa del código fuente
(agosto 2026), no solo en el diseño planeado.

## 1. Qué es este proyecto

Migración y mejora (no solo port 1:1) de una app Android AR de turismo para el Parque
Arqueológico Kaminaljuyú, a iOS. La versión Android tiene arquitectura monolítica (toda la
lógica del tour concentrada en `HelloGeoRenderer`); la versión iOS introduce una arquitectura
modular desacoplada por EventBus. Esa mejora arquitectónica **es** la contribución de tesis,
así que la precisión de esta documentación importa para la defensa.

Guía a los visitantes por montículos (POIs) arqueológicos usando proximidad GPS, AR con
modelos 3D, y una guía virtual maya en video pregrabado (español/inglés).

## 2. Equipo y ownership de módulos

| Módulo | Owner | Carpeta |
|---|---|---|
| Arquitectura general, integración, LanguageModule, UIModule/UICoordinator | Aleeee (Mónica) | `Shared/`, `App/`, `FeatureModules/LanguageModule/` |
| GPSModule | Santiago | `FeatureModules/GPSModule/` |
| ARModule | Andre Jo | `FeatureModules/ARModule/` |
| VirtualGuideModule | Gaby | `FeatureModules/VirtualGuideModule/` |

## 3. Estructura de carpetas (real, verificada)

```
ArTourKaminaljuyu/
├── App/
│   ├── ArTourKaminaljuyuApp.swift
│   ├── AppRouter/AppRouter.swift
│   ├── AppDelegate/              ← vacía, planeada, no implementada
│   ├── DependencyContainer/      ← vacía, planeada, no implementada
│   └── UICoordinator/            ← todas las Views de navegación/UI
├── ContentView.swift              ← contiene GuidedTourOverlay + ContentView (raíz real de navegación)
├── FeatureModules/
│   ├── GPSModule/
│   │   ├── API Layer/GPSModuleInterface.swift   ← única puerta pública del módulo
│   │   ├── Models/, Navigation/, Services/
│   ├── ARModule/
│   │   ├── Rendering/ARViewController.swift
│   │   ├── Models/, Services/
│   ├── LanguageModule/
│   │   ├── Services/LanguageService.swift
│   │   ├── Content/LocalizedStrings.swift
│   │   └── Resources/{Spanish,English}/   ← videos .mov
│   └── VirtualGuideModule/
│       └── Views/VirtualGuideView.swift (contiene el ViewModel también)
└── Shared/
    ├── EventBus/EventBus.swift
    ├── AppStateManager/AppStateManager.swift
    ├── Models/AppState.swift
    └── PersistanceManager/       ← vacía, planeada, no implementada
```

**Importante:** todo vive en un solo target de Xcode. La "modularidad" es organizacional
(carpetas + una interfaz pública por módulo tipo `GPSModuleInterface`), no está forzada por
el compilador ni por Swift Packages separados. Documéntalo así en la tesis — es una decisión
de alcance válida, pero no es lo mismo que módulos con límites duros.

## 4. Cómo se deben comunicar los módulos (regla de arquitectura)

**Regla general: los módulos NO se llaman entre sí directamente. Se comunican por dos vías,
cada una con un propósito distinto:**

1. **EventBus (`Shared/EventBus/EventBus.swift`)** — para *notificaciones* de dominio,
   eventos que ya ocurrieron y que a varios módulos les puede interesar saber.
   Implementado con Combine `PassthroughSubject<AppEvent, Never>`, patrón Observer.

   ```swift
   enum AppEvent {
       case poiReached(poiId: String)
       case tourStarted
       case tourCompleted        // ⚠️ declarado, nunca publicado (ver §6)
       case poiChanged(poiId: String?)  // ⚠️ declarado, nunca usado (ver §6)
       case locationUpdated(latitude: Double, longitude: Double, heading: Double)
       case languageChanged(language: String)
       case nextPOIRequested
       case tourEndRequested
       case tourEndCompleted
   }
   ```

   Publicar: `EventBus.shared.publish(.tourStarted)`
   Suscribirse: `EventBus.shared.publisher.sink { event in ... }`

2. **Interfaces públicas por módulo** (`GPSModuleInterface`, `LanguageService`) — para
   *comandos* (arrancar/detener algo) y *lectura de estado publicado* (`@Published` vars
   vía Combine). Cada módulo expone **una sola clase `.shared`** como su API pública; nadie
   fuera del módulo debe tocar sus `Services/` o `Models/` internos directamente.

   Ejemplo real: `ARModule` y `VirtualGuideModule` leen `GPSModuleInterface.shared.$userLocation`,
   `.nearestPOI`, `.allPOIs` — nunca tocan `LocationService` o `ProximityService` directamente.

**Regla práctica de cuándo usar cada uno:**
- ¿Es un comando imperativo, algo que un solo lugar controla (arrancar tracking, cambiar
  idioma)? → llamada directa al método de la interfaz del módulo (`GPSModuleInterface.shared.startTour()`).
- ¿Es un hecho que ya pasó y a otros módulos les interesa reaccionar? → `EventBus`.

Esta separación comando/notificación **sí está siendo respetada consistentemente** en el
código actual — es la parte de tu arquitectura que mejor se está cumpliendo. Documéntala
explícitamente como decisión de diseño en la tesis, porque hoy es implícita (nadie lo
escribió, simplemente pasó así).

### AppStateManager — estado global (ver advertencia en §6)

`AppStateManager.shared` (Combine `ObservableObject`) es el diseño para tener un
**single source of truth** del estado del tour (`AppState`: `.idle` / `.inTour(activePOIId:)`
/ `.completed`), separado del estado de navegación (`AppRouter`). En el diseño, los módulos
deberían leer `AppStateManager.shared.currentState` en vez de inferir el estado desde eventos
sueltos. **Ahora mismo esto no está pasando en el flujo real — ver §6.**

### AppRouter — navegación

`AppRouter.shared` (`currentRoute: AppRoute` = `.menu` / `.tourControls` / `.guidedTour`)
sí está en uso activo y es lo que efectivamente controla qué pantalla se muestra desde
`ContentView.swift`.

## 5. Mapeo POI → video (LanguageModule)

Convención de nombres en Android `strings.xml` migrada: `poi_[nombre]_title`,
`poi_[nombre]_findings`, `poi_[nombre]_function` (interpretación arqueológica de uso
social/ritual — distinto de `_findings`, que es evidencia física de construcción).

Mapeos POI → video confirmados: `monticulo_6` → `M CII 6_final`, `acropolis` → `Acrópolis CII 4_final`,
`monticulo_3` → `M CII 3_final`, `tourCompleted` → `Despedida_final`. 16 videos por idioma,
en `.mov` HEVC con canal alfa (fondo blanco removido), en `LanguageModule/Resources/{Spanish,English}/`.

`LanguageService.setLanguage()` solo puede cambiarse **antes** de iniciar el tour (decisión
de alcance simplificada, no a mitad de experiencia).

## 6. Deuda técnica conocida (léelo antes de tocar arquitectura)

Esta sección existe para que ninguna sesión futura de Claude reintroduzca un patrón muerto
pensando que es el flujo real, ni se confunda con archivos huérfanos. Es honestidad
necesaria para la tesis, no un fallo que haya que ocultar.

1. **`App/UICoordinator/ARTourView.swift` es código huérfano.** No se instancia en
   ningún lado del proyecto. Fue reemplazado por `GuidedTourOverlay` dentro de
   `ContentView.swift`, que hace lo mismo (AR + guía virtual + overlay de mapa) pero con
   lógica de arranque/parada de GPS distinta y correcta. **Antes de tocar el flujo de tour
   guiado, confirma que estás editando `ContentView.swift`, no `ARTourView.swift`.**
   Candidato a eliminar del repo, o a documentar explícitamente como versión anterior
   archivada si se quiere conservar el historial de diseño.

2. **`AppStateManager` casi no se usa en el flujo real.** Solo se llama
   `AppStateManager.shared.setActivePOI()`, y únicamente desde el `ARTourView.swift` huérfano
   (punto 1) — es decir, en la práctica **nunca se ejecuta**. `startTour()`, `completeTour()`
   y `reset()` no se llaman de ningún lado. La navegación real depende de `AppRouter.currentRoute`
   más `@State` local en `ContentView` (`isLoading`, `showInstructions`, `showTerms`), no del
   `AppState` (`idle`/`inTour`/`completed`) que diseñaste como fuente única de verdad.
   Esto es una brecha real entre arquitectura documentada y arquitectura implementada —
   dos opciones honestas para la tesis: (a) refactorizar `ContentView`/`GuidedTourOverlay`
   para que sí lean y escriban `AppStateManager.shared.currentState`, o (b) documentar
   conscientemente que `AppRouter` terminó absorbiendo esa responsabilidad y que
   `AppStateManager` quedó fuera de alcance / infrautilizado, explicando por qué.

3. **Dos casos de `AppEvent` están muertos:**
   - `.poiChanged(poiId:)` — declarado, nunca publicado ni escuchado por nadie.
   - `.tourCompleted` — se escucha en `VirtualGuideView.start()` (dispara el video de
     despedida vía `enqueue(videoDespedida)`), pero **nadie lo publica**. En la práctica el
     video de despedida se dispara por `.tourEndRequested`, que sí funciona. Limpiar el enum
     (quitar los dos casos, o implementarlos si tienen un propósito futuro) antes de la
     entrega final, para que el `EventBus` documentado coincida con el real.

4. **Carpetas vacías = features planeadas y nunca construidas:** `Shared/PersistanceManager/`,
   `App/DependencyContainer/`, `App/AppDelegate/`. Si no se van a implementar, elimínalas del
   repo antes de la entrega (una carpeta vacía en el zip final se ve como algo a medias).
   Si se documentan en la tesis como "fuera de alcance", que la tesis lo diga explícitamente
   con esas palabras, no como si estuvieran implementadas.

5. **Archivos de prueba/scratch en carpetas de producción:**
   `FeatureModules/GPSModule/Models/POIRegistryTest.swift`,
   `FeatureModules/GPSModule/Navigation/TestMapView.swift`,
   `FeatureModules/ARModule/Rendering/test.swift` (vacío).
   Mover a una carpeta `DevScratch/` fuera del target de release, o eliminar, antes de
   entregar el repo final — probablemente de Santiago/Andre Jo, vale la pena confirmar con
   ellos si aún se usan para debug.

## 7. Reglas de comunicación al escribir código nuevo

- Nunca importar/instanciar `Services` o `Models` internos de otro módulo directamente.
  Pasar siempre por la interfaz pública (`GPSModuleInterface.shared`, `LanguageService.shared`).
- Un evento de dominio nuevo → agrégalo a `AppEvent` en `EventBus.swift` y documenta aquí
  quién lo publica y quién se suscribe, para que no vuelva a pasar lo del punto 6.3.
- Si vas a leer o escribir estado que debería sobrevivir a la navegación entre pantallas,
  primero evalúa si le corresponde a `AppStateManager` (y si es así, conéctalo de verdad,
  no dupliques con `@State` local — ver punto 6.2).
- Comandos de arranque/parada de un módulo (tracking GPS, sesión AR, tour) van como llamada
  directa al método de la interfaz pública del módulo, no como evento.
- Commits en inglés, identidad Git `alesalvatierra`.

## 8. Reglas de operación para Claude en este repo

**Nunca hacer commit, push, ni ningún cambio en git (branch, merge, checkout, etc.) sin
confirmación explícita de Aleeee para esa acción puntual.** Esto incluye `git add`,
`git commit`, `git push`, crear o cambiar de branch.

**Pedir confirmación antes de cualquier acción, incluyendo acciones de solo lectura**
(leer un archivo, listar el repo, correr `git status`, etc.). No asumir que "solo leer" no
necesita permiso — preguntar siempre primero, describir qué se va a hacer, y esperar
confirmación antes de ejecutar.

Esto aplica en todo momento de la sesión, no solo al principio.

## 9. Entorno de desarrollo

- Abrir siempre `.xcworkspace` (no `.xcodeproj`) — CocoaPods para Google Maps/Places.
- `Secrets.xcconfig` (gitignored) con la API key de Google Maps; usar `Secrets.xcconfig.example`
  como plantilla.
- AR requiere dispositivo físico (no funciona en simulador).
- Video processing offline: Python (numpy, PIL, scipy) + ffmpeg + `avconvert` para HEVC con
  canal alfa.
