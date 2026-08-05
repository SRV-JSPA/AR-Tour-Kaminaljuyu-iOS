# CLAUDE.md — AR Tour Kaminaljuyú (iOS)

Este archivo documenta la arquitectura real del proyecto para que cualquier sesión de Claude
(o cualquier persona nueva en el equipo) entienda cómo está construido, cómo se deben
comunicar los módulos, y qué partes de la arquitectura propuesta en la tesis todavía no
están completamente implementadas. Está basado en una revisión directa del código fuente
(agosto 2026, post-refactor arquitectónico completado en la branch `refactor-arq`).

## 1. Qué es este proyecto

Migración y mejora (no solo port 1:1) de una app Android AR de turismo para el Parque
Arqueológico Kaminaljuyú, a iOS. La versión Android tiene arquitectura monolítica (toda la
lógica del tour concentrada en `HelloGeoRenderer`); la versión iOS introduce una arquitectura
modular desacoplada por EventBus + interfaces públicas + estado global centralizado. Esa
mejora arquitectónica **es** la contribución de tesis.

Guía a los visitantes por montículos (POIs) arqueológicos usando proximidad GPS, AR con
modelos 3D, y una guía virtual maya en video pregrabado (español/inglés).

## 2. Equipo y ownership de módulos

| Módulo | Owner | Carpeta |
|---|---|---|
| Arquitectura general, integración, LanguageModule, UIModule/UICoordinator | Aleeee (Mónica) | `Shared/`, `App/`, `FeatureModules/LanguageModule/` |
| GPSModule | Santiago | `FeatureModules/GPSModule/` |
| ARModule | Andre Jo | `FeatureModules/ARModule/` |
| VirtualGuideModule | Gaby | `FeatureModules/VirtualGuideModule/` |

## 3. Estructura de carpetas (real, verificada post-refactor)

```
ArTourKaminaljuyu/
├── App/
│   ├── ArTourKaminaljuyuApp.swift     ← entry point; instancia AppContainer, inyecta env
│   ├── AppRouter/AppRouter.swift
│   ├── DependencyContainer/
│   │   └── AppContainer.swift          ← factory de servicios + .production() / .mock()
│   └── UICoordinator/                  ← views SwiftUI de navegación / menú / info
├── ContentView.swift                    ← raíz real de navegación (GuidedTourOverlay + ContentView)
├── FeatureModules/
│   ├── GPSModule/
│   │   ├── API Layer/
│   │   │   ├── GPSModuleInterface.swift  ← interfaz pública
│   │   │   └── AppConfig.swift            ← constantes de tour + proximidad
│   │   ├── Models/{POILocation, POIRegistry}
│   │   ├── Navigation/{TourManager, RouteNavigator, RouteConfig, MapViewRepresentable, GeoUtils}
│   │   └── Services/{LocationService, ProximityService, LocationPermissionsHelper, GeoMath}
│   ├── ARModule/
│   │   ├── API Layer/
│   │   │   └── ARModuleInterface.swift    ← interfaz pública (placeholder) + ARModuleView (representable)
│   │   ├── Models/ARConfig.swift
│   │   ├── Rendering/ARViewController.swift
│   │   └── Services/{ARSceneManager, ARGuideArrowManager}
│   ├── LanguageModule/
│   │   ├── Services/LanguageService.swift  ← interfaz pública (`.shared`)
│   │   ├── Content/LocalizedStrings.swift
│   │   └── Resources/{Spanish,English}/    ← .mov videos + subtitles data
│   └── VirtualGuideModule/
│       ├── API Layer/
│       │   └── VirtualGuideModuleInterface.swift  ← interfaz pública (ObservableObject grande, facade Ruta A)
│       ├── Models/TranscriptLine.swift
│       └── Views/{VirtualGuideView, VideoTranscripts}
└── Shared/
    ├── EventBus/EventBus.swift              ← Combine PassthroughSubject de AppEvent
    ├── AppStateManager/AppStateManager.swift ← fuente autoritativa de tour state
    └── Models/{AppState, ColorExtension, ArrayExtension}
```

**Importante:** todo vive en un solo target de Xcode. La "modularidad" es organizacional
(carpetas + una interfaz pública por módulo tipo `GPSModuleInterface`), no está forzada por
el compilador ni por Swift Packages separados. 

## 4. Cómo se comunican los módulos (regla de arquitectura)

**Regla general: los módulos NO se llaman entre sí directamente. Se comunican por tres vías,
cada una con un propósito distinto:**

### 4.1 Comandos → llamada directa a interfaz pública

Para acciones imperativas de "arrancar/detener/cambiar algo" que un solo lugar controla:

```swift
// En SwiftUI Views (patrón preferido, post-refactor):
@EnvironmentObject var gps: GPSModuleInterface
@EnvironmentObject var appState: AppStateManager
// ...
gps.startTour()
appState.startTour()

// En UIKit / boundaries donde @EnvironmentObject no fluye:
GPSModuleInterface.shared.startTracking()
AppStateManager.shared.reset()
```

### 4.2 Notificaciones → EventBus

Para "algo ya pasó, a varios módulos les puede interesar reaccionar":

```swift
enum AppEvent {
    case languageChanged(language: String)   // publicado por LanguageService; sin suscriptores hoy (mecanismo listo)
    case nextPOIRequested                    // publicado por ARModule; escuchado por VirtualGuideModule
    case tourEndRequested                    // publicado por ARModule / ContentView; escuchado por VirtualGuideModule
    case tourEndCompleted                    // publicado por VirtualGuideModule (video Despedida terminó); escuchado por ContentView
}
```

Publicar: `EventBus.shared.publish(.nextPOIRequested)`
Suscribirse: `EventBus.shared.publisher.sink { event in ... }`

### 4.3 Observación reactiva de estado → `@Published`

Para reads de estado de otros módulos (más eficiente y directo que eventos):

```swift
// Views observan reactivamente:
@EnvironmentObject var gps: GPSModuleInterface
// gps.$userLocation, gps.$tourState, gps.$nearestPOI son @Published

// Módulos observan otros módulos internamente:
GPSModuleInterface.shared.$nearestPOI.sink { ... }
AppStateManager.shared.$currentState.sink { ... }
```

### Regla práctica de cuándo usar cada uno

- ¿Es un comando imperativo, algo que un solo lugar controla (arrancar tracking, cambiar
  idioma)? → **llamada directa** al método de la interfaz.
- ¿Es un hecho puntual que ya pasó y a otros módulos les interesa reaccionar (video terminó,
  usuario tapeó Next)? → **EventBus**.
- ¿Es estado continuo/reactivo (posición del usuario, estado del tour)? → **observación de
  `@Published`** en la interfaz pública.

Esta separación está siendo respetada en todo el código actual. Es el corazón de la arquitectura

### 4.4 AppContainer + inyección de dependencias

`App/DependencyContainer/AppContainer.swift` es el factory central. `ArTourKaminaljuyuApp`
lo instancia una vez y inyecta cada servicio individualmente vía `.environmentObject`:

```swift
ContentView()
    .environmentObject(container.gps)
    .environmentObject(container.language)
    .environmentObject(container.ar)
    .environmentObject(container.virtualGuide)
    .environmentObject(container.appState)
    .environmentObject(container.router)
```

**Nota:** `EventBus` NO se inyecta como env (no es `ObservableObject`, es un message bus).
Publicadores usan `EventBus.shared.publish(...)` directo.

**Excepciones justificadas** al patrón `@EnvironmentObject` (donde se usa `.shared`):
- `ARViewController` y `BackConfirmationView` — UIKit, el env de SwiftUI no fluye a UIViewController.
- `LocalizedStrings.get(key)` — static helper, no es un view.
- `VirtualGuideModuleInterface` implementación interna — lee `GPSModuleInterface.shared`,
  `LanguageService.shared`, `AppStateManager.shared` desde adentro del propio módulo (una
  interfaz no puede ownership de otra via SwiftUI env; es implementation detail correcto).

### 4.5 AppStateManager — fuente autoritativa del estado del tour

`AppStateManager.shared` (Combine `ObservableObject`) es el single source of truth del
estado del tour (`AppState`: `.idle` / `.inTour(activePOIId:)` / `.completed`), separado
del estado de navegación (`AppRouter`).

Flujo completo del tour post-refactor:

1. Usuario tapea "Iniciar" en TourControls → `ContentView.onStartTour`:
   - `appState.startTour()` → `currentState = .inTour(activePOIId: nil)`
   - `gps.startTour()` (inicia TourManager en GPSModule)
   - `router.navigateTo(.guidedTour)`
2. GuidedTourOverlay monta → `.onAppear`:
   - `guideVM.playIntroSequence()` (encola Datos generales + Datos arqueológicos)
   - `guideVM.start()` subscribe a EventBus + AppState + GPS
3. VirtualGuide observa `AppStateManager.$currentState`, ve `.inTour`, dispara `startWalking()`
   → encola Indicación flecha después de intros.
4. Usuario camina, proximidad dispara videos según distancia.
5. Usuario en AR tapea Next → ARModule publica `.nextPOIRequested`, VirtualGuide limpia cola.
6. Usuario en último POI o finaliza → `.tourEndRequested` → VirtualGuide reproduce Despedida.
7. Despedida termina → VirtualGuide publica `.tourEndCompleted`:
   - `appState.completeTour()` → `currentState = .completed`
   - `gps.stopTour()`
   - `router.navigateTo(.menu)`

### AppRouter — navegación

`AppRouter.shared` (`currentRoute: AppRoute` = `.menu` / `.tourControls` / `.guidedTour`)
maneja las rutas principales. `.instructions` y `.terms` se controlan con `@State` locales
en `ContentView` — es una brecha menor documentada en §6 (trabajo futuro: expandir el enum).

## 5. Mapeo POI → video (LanguageModule)

Convención de nombres en Android `strings.xml` migrada: `poi_[nombre]_title`,
`poi_[nombre]_findings`, `poi_[nombre]_function` (interpretación arqueológica de uso
social/ritual — distinto de `_findings`, que es evidencia física de construcción).

Mapeos POI → video confirmados: `monticulo_6` → `M CII 6_final` (mapeado como `M CII 5_final`
en el diccionario actual, ver ambigüedad de datos §6), `acropolis` → `Estructura E_final`,
`monticulo_3` → `M CII 13_final`, `tourCompleted` → `Despedida_final`. 16 videos por idioma,
en `.mov` HEVC con canal alfa (fondo blanco removido), en `LanguageModule/Resources/{Spanish,English}/`.

Los archivos `.mp4` en `Resources/Spanish/` son sources pre-procesamiento no referenciados
por el código (bundle bloat documentable, ver §6).

`LanguageService.setLanguage()` solo puede cambiarse **antes** de iniciar el tour (decisión
de alcance simplificada, no a mitad de experiencia).

## 6. Deuda técnica conocida (post-refactor)

Esta sección lista **solo lo que sigue pendiente** después del refactor de la branch
`refactor-arq`. Los items originales resueltos (ARTourView huérfano, eventos zombies,
AppStateManager desconectado, carpetas vacías) fueron removidos porque ya no aplican.

### 6.1 Coordenadas de POIs inconsistentes

- Los 4 primeros POIs (`informacion_inicial`, `monticulo_6`, `acropolis`, `monticulo_3`)
  tienen coordenadas en `(14.60x, -90.48x)` — lejos del resto del sitio.
- Los otros 7 POIs (`monticulo_5`, `_7`, `_8`, `_12`, `palangana`, `_14`, `_13`) están en
  `(14.63x, -90.54x)`, coherentes con los conectores de `RouteConfig`.
- **Documentado en tesis como fuera de alcance** — no es una decisión arquitectónica sino de
  datos de contenido pendiente de curaduría con Santiago.

### 6.2 `AppConfig.tourStartLatitude/Longitude` no coincide con el sitio

- Valor actual `(14.6748361, -90.5520308)` está fuera del parque real.
- **Es intencional para testing en casa** (ver §11 Decisiones de diseño). Antes de release
  final se ajusta al centro real del parque.

### 6.3 `GeoMath` + `GeoUtils` duplican Haversine

Dos implementaciones de la misma matemática Haversine + bearing en `GPSModule/Services/GeoMath.swift`
y `GPSModule/Navigation/GeoUtils.swift`. Los llamadores están divididos:
- `ProximityService`, `TourManager`, `RouteNavigator`, `RouteConfig` → usan `GeoUtils`
- Nada usa `GeoMath` post-refactor (`ProximityDetector` fue borrado).

Consolidar en `GeoUtils` (tiene `compensatedDistance`, único). Trabajo pendiente para Santiago.

### 6.4 `ARViewController` como God Object (Ruta B ARModule)

522 líneas mezclando setup escena, gestos, UI programática, modal de info, subscripción a
GPS/EventBus, máquina de estado local (`currentPOIIndex`, `hasPlacedModel`), `ARSessionDelegate`
y `BackConfirmationView` embebido. Descomposición pendiente:
- `ARSessionController` (lifecycle)
- `ARTourController` (progresión POI + events)
- `ARControlsView` (UI botones)
- `ARInfoSheet` (modal)
- `ARViewController` thin

Trabajo pendiente para Andre Jo (Ruta B del refactor).

### 6.5 `VirtualGuideModuleInterface` como facade grande (Ruta B VirtualGuideModule)

La clase pública tiene ~480 líneas: queue de videos, máquina de estados de proximidad,
AVPlayer orchestration, transcripción, config de audio. Ruta A (facade) es correcta para el
scope actual. Ruta B (descomposición) queda pendiente:
- `VideoPlaybackService` (AVPlayer + observers)
- `VideoQueueManager` (queue + skip logic)
- `ProximityPlaybackController` (máquina 3 fases)
- `TranscriptService` (loading + cue lookup)
- `VirtualGuideModuleInterface` thin, orquesta los servicios

Trabajo pendiente para Gaby.

### 6.6 Hack de 300ms en `ContentView.onFinalize`

```swift
onFinalize: {
    router.navigateTo(.guidedTour)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        EventBus.shared.publish(.tourEndRequested)
    }
}
```

El delay compensa que `GuidedTourOverlay` monte y `guideVM.start()` subscriba antes de
publicar el evento. Es un smell — la solución limpia sería pasar un flag a
`GuidedTourOverlay` para que dispare Despedida directamente al montar en modo finalize.
No bloquea nada, pendiente de refactor.

### 6.7 `AppRouter` con navegación fragmentada

El enum `AppRoute` cubre solo `.menu` / `.tourControls` / `.guidedTour`. Las views de
`InstructionsView` y `TermsView` se manejan con `@State private var showInstructions/showTerms`
locales en ContentView. `SplashView` con `@State private var isLoading`. `.freeTour` no tiene
case (usa modal Coming Soon).

Expansión del enum queda como trabajo futuro para consolidar navegación.

### 6.8 `.languageChanged` sin suscriptores

`LanguageService.setLanguage()` publica `.languageChanged` al EventBus, pero ningún módulo
lo escucha. El evento es semánticamente válido (mecanismo listo para consumidor futuro que
necesite reaccionar a cambio de idioma), pero por ahora está "esperando". Documentable —
no es zombie porque el publisher es intencional.

### 6.9 `.mp4` legacy files en `Resources/Spanish/`

Además de los `.mov` (los que usa el código), la carpeta tiene versiones `.mp4` de varios
videos que no se referencian nunca. Bundle bloat pendiente de limpieza — reduce el tamaño
del .ipa final. Confirmar con equipo antes de borrar.

### 6.10 Sin tests unitarios

El framework de tests (Swift Testing) y el pattern (`AppContainer.mock()` como placeholder)
están listos, pero no hay tests escritos. Requisito de tesis pendiente.

## 7. Reglas de comunicación para código nuevo

- **Views SwiftUI nuevas**: preferir `@EnvironmentObject var xxx: XxxInterface` sobre `.shared`.
- **Excepciones justificadas** para usar `.shared`: UIKit boundaries (UIViewController y
  UIHostingController hijos), implementación interna de módulos, static helpers como
  `LocalizedStrings.get()`.
- **Nunca importar/instanciar `Services` o `Models` internos de otro módulo directamente.**
  Pasar siempre por la interfaz pública (`GPSModuleInterface`, `LanguageService`,
  `ARModuleInterface`, `VirtualGuideModuleInterface`).
- **Un evento de dominio nuevo** → agrégalo a `AppEvent` en `EventBus.swift` y documenta
  quién lo publica y quién se suscribe (para no reintroducir eventos zombies).
- **Estado del tour** → `AppStateManager.shared` es fuente autoritativa. Nadie más maneja
  `AppState`; se actualiza vía `startTour()`, `completeTour()`, `reset()`, `setActivePOI()`.
- **Comandos de arranque/parada** de un módulo (tracking GPS, sesión AR, tour) van como
  llamada directa al método de la interfaz pública del módulo, no como evento.
- **Reads reactivos de estado externo** → observar `@Published` de la interfaz pública,
  no crear un evento para propagarlo.
- **Commits en inglés**, identidad Git `alesalvatierra`.

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

## 10. Zonas rojas para trabajo en paralelo

Para Andre Jo, Gaby y Santiago trabajando en sus módulos: **evitar tocar estas zonas sin
coordinar con Aleeee**, porque son puntos donde un cambio impacta a todo el proyecto.

- **`Shared/EventBus/EventBus.swift`** — cambios al enum `AppEvent` rompen todos los
  suscriptores. Agregar casos es OK; renombrar/borrar requiere coordinar.
- **`Shared/AppStateManager/AppStateManager.swift`** — es la fuente autoritativa del tour
  state. Cambios a métodos públicos o al enum `AppState` requieren actualizar consumidores.
- **`App/DependencyContainer/AppContainer.swift`** — DI setup; agregar un servicio nuevo
  al container requiere también inyectarlo en `ArTourKaminaljuyuApp`.
- **`App/AppRouter/AppRouter.swift`** — enum de navegación; agregar cases requiere manejarlos
  en `ContentView`.
- **`App/ArTourKaminaljuyuApp.swift`** — root injection; cambios afectan toda la app.
- **`ContentView.swift`** — raíz real de navegación + orquestación del tour. Muy denso,
  coordinar antes de tocar.
- **Interfaces públicas de módulos** (`GPSModuleInterface`, `LanguageService`,
  `ARModuleInterface`, `VirtualGuideModuleInterface`) — cambios a la API pública rompen
  consumers en otros módulos. Cambios a implementación interna son libres.

**Zonas verdes (libres para trabajar):**
- Andre Jo: `FeatureModules/ARModule/{Rendering,Services,Models}` — internals del AR.
- Gaby: `FeatureModules/VirtualGuideModule/{Views}` + implementación interna de
  `VirtualGuideModuleInterface` (mientras la API pública no cambie).
- Santiago: `FeatureModules/GPSModule/{Services,Navigation,Models}` — internals del GPS.

## 11. Decisiones de diseño intencionales

Estas parecen "raras" al leer el código pero son decisiones conscientes. Documentadas aquí
para que ninguna sesión futura las "arregle" pensando que son bugs.

- **`ARModuleView()` siempre presente en el `ZStack` root de ContentView** (no lazy-loaded).
  `ARWorldTrackingConfiguration` tarda 3-5s en warmup; precargar desde el splash elimina
  ese delay perceptible cuando el usuario inicia el tour. Trade-off aceptado: batería +
  cámara activa desde el splash. Uso primario de la app: visita presencial corta.
- **`AppConfig.tourStartLatitude/Longitude` = (14.6748361, -90.5520308)** — coordenada de
  ubicación de desarrollo para poder testear `TourManager.startTour()` sin ir al sitio.
  Se ajustará al centro real del parque antes del release final.
- **Sin persistencia** (idioma seleccionado, tour progress, etc.) — decisión consciente de
  scope de tesis. Uso primario: visita física única al parque; el usuario reabre la app y
  reselecciona idioma. La carpeta `Shared/PersistanceManager/` que existía como placeholder
  fue removida en el refactor.
- **Un solo target de Xcode**, no Swift Packages separados. La modularidad es organizacional
  (carpetas + una interfaz pública por módulo tipo `GPSModuleInterface`), no forzada por el
  compilador.
- **`.languageChanged` se publica sin suscriptores** — el mecanismo está listo; futuros
  consumidores (por ejemplo un módulo que necesite invalidar caches al cambiar idioma) lo
  podrán consumir sin cambios al publicador.
- **`EventBus` se reserva para notificaciones de dominio discretas**; cambios de estado
  continuos (`AppState`, `tourState`, `userLocation`) se propagan vía `@Published`, más
  eficiente y sin problemas de timing.
- **`ARModule` no se suscribe al `EventBus`** aunque publica en él; reacciona al estado del
  tour observando `GPSModuleInterface.$tourState` (`@Published`), que es más apropiado para
  reads de estado continuo.
- **`AppStateManager.startTour()` NO publica al EventBus**; los consumidores observan
  `$currentState`. Publicar sería redundante con la observación reactiva.
- **Excepciones justificadas al patrón `@EnvironmentObject`** (documentadas en §4.4): UIKit
  boundaries (`ARViewController`, `BackConfirmationView`), implementación interna de
  `VirtualGuideModuleInterface`, y helper estático `LocalizedStrings.get()`.

## 12. Trabajo futuro documentado

Además de la deuda técnica de §6, estos son ítems que quedan como "future work" para
después de la entrega inicial:

- **Tests unitarios** con `AppContainer.mock()` (framework: Swift Testing).
- **Ruta B ARModule**: descomponer `ARViewController` en Session/Tour/Controls/Info (§6.4).
- **Ruta B VirtualGuideModule**: extraer `VideoPlaybackService`, `VideoQueueManager`,
  `ProximityPlaybackController`, `TranscriptService` (§6.5).
- **Consolidar `GeoMath` + `GeoUtils`** en uno (§6.3).
- **Expandir `AppRouter`** para consolidar navegación (`.instructions`, `.terms`, `.freeTour`,
  `.splash` como cases del enum) (§6.7).
- **Fix del hack 300ms** en `onFinalize` (§6.6).
- **Design tokens** — centralizar la paleta de colores hex hardcodeada en un `AppColors`
  enum en vez de repetir `Color(hex: "#XXXXXX")` en cada view.
- **Implementación real de Tour Libre** (hoy es placeholder con modal Coming Soon).
- **Persistencia del idioma** (si se reconsidera scope de tesis).
- **Limpieza de `.mp4` legacy** en `Resources/Spanish/`.

---

**Este archivo se actualiza con cada refactor mayor. Última revisión: agosto 2026,
post-completación del refactor arquitectónico (branch `refactor-arq`).**
