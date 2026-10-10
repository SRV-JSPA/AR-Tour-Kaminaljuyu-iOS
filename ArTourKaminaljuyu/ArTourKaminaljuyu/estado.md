# Estado del proyecto — AR Tour Kaminaljuyú (iOS)

Este archivo describe el estado actual del proyecto: cómo está construido, cómo se comunican
los módulos, qué deuda técnica queda pendiente y qué decisiones de diseño se tomaron. Está
basado en una revisión directa del código fuente de la branch `refactor-arq`.

## 1. Qué es este proyecto

Migración y mejora (no solo port 1:1) de una app Android AR de turismo para el Parque
Arqueológico Kaminaljuyú, a iOS. La versión Android tiene arquitectura monolítica (toda la
lógica del tour concentrada en `HelloGeoRenderer`); la versión iOS introduce una arquitectura
modular basada en interfaces públicas por módulo, un EventBus y estado del tour centralizado.

Guía a los visitantes por montículos (POIs) arqueológicos usando proximidad GPS, AR con
modelos 3D, y una guía virtual maya en video pregrabado (español/inglés).

## 2. Equipo y ownership de módulos

| Módulo | Owner | Carpeta |
|---|---|---|
| Arquitectura general, integración, LanguageModule, UIModule/UICoordinator | Aleeee (Mónica) | `Shared/`, `App/`, `FeatureModules/LanguageModule/` |
| GPSModule | Santiago | `FeatureModules/GPSModule/` |
| ARModule | Andre Jo | `FeatureModules/ARModule/` |
| VirtualGuideModule | Gaby | `FeatureModules/VirtualGuideModule/` |

## 3. Estructura de carpetas

```
ArTourKaminaljuyu/
├── App/
│   ├── ArTourKaminaljuyuApp.swift     ← entry point; instancia AppContainer, inyecta env
│   ├── AppRouter/AppRouter.swift
│   ├── DependencyContainer/
│   │   └── AppContainer.swift          ← factory de servicios (.production())
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
│   │   │   └── ARModuleInterface.swift    ← interfaz pública + ARModuleView (representable)
│   │   ├── Models/ARConfig.swift
│   │   ├── Rendering/ARViewController.swift
│   │   └── Services/{ARSceneManager, ARGuideArrowManager}
│   ├── LanguageModule/
│   │   ├── Services/LanguageService.swift  ← interfaz pública (`.shared`)
│   │   ├── Content/LocalizedStrings.swift
│   │   └── Resources/{Spanish,English}/    ← videos .mov
│   └── VirtualGuideModule/
│       ├── API Layer/
│       │   └── VirtualGuideModuleInterface.swift  ← interfaz pública (ObservableObject grande, facade)
│       ├── Models/TranscriptLine.swift
│       └── Views/{VirtualGuideView, VideoTranscripts}
└── Shared/
    ├── EventBus/EventBus.swift              ← Combine PassthroughSubject de AppEvent
    ├── AppStateManager/AppStateManager.swift ← fuente autoritativa del estado del tour
    └── Models/{AppState, ColorExtension, ArrayExtension}
```

Todo vive en un solo target de Xcode. La modularidad es organizacional (carpetas + una
interfaz pública por módulo, tipo `GPSModuleInterface`); no está forzada por el compilador
ni por Swift Packages separados.

Frameworks principales: SwiftUI, Combine, CoreLocation, Google Maps SDK for iOS (mapa),
ARKit + SceneKit (realidad aumentada), AVFoundation / AVKit (video).

## 4. Cómo se comunican los módulos

Los módulos no usan los `Services` ni `Models` internos de otros módulos: toda interacción
pasa por la interfaz pública de cada módulo, por una de tres vías.

### 4.1 Comandos → llamada directa a la interfaz pública

Acciones imperativas de "arrancar/detener/cambiar algo":

```swift
// En SwiftUI Views:
@EnvironmentObject var gps: GPSModuleInterface
@EnvironmentObject var appState: AppStateManager
gps.startTour()
appState.startTour()

// En UIKit / boundaries donde @EnvironmentObject no fluye:
GPSModuleInterface.shared.stopTour()
AppStateManager.shared.reset()
```

### 4.2 Notificaciones → EventBus

Sucesos puntuales a los que uno o varios módulos reaccionan:

```swift
enum AppEvent {
    case languageChanged(language: String)   // publicado por LanguageService; sin suscriptores
    case nextPOIRequested                    // publicado por ARModule; escuchado por GPSModule (avanza la ruta)
                                             // y VirtualGuideModule (detiene video y limpia cola)
    case tourEndRequested                    // publicado por ARModule / ContentView; escuchado por VirtualGuideModule
    case tourEndCompleted                    // publicado por VirtualGuideModule (terminó Despedida); escuchado por ContentView
}
```

Publicar: `EventBus.shared.publish(.nextPOIRequested)`
Suscribirse: `EventBus.shared.publisher.sink { event in ... }`

### 4.3 Observación reactiva de estado → `@Published`

Estado continuo de otros módulos:

```swift
// Views:
@EnvironmentObject var gps: GPSModuleInterface
// gps.$userLocation, gps.$tourState, gps.$nearestPOI son @Published

// Módulos que observan a otros:
GPSModuleInterface.shared.$nearestPOI.sink { ... }
AppStateManager.shared.$currentState.sink { ... }
VirtualGuideModuleInterface.shared.$currentPOIVideoCompleted.sink { ... }   // desde ARModule
```

Distribución actual:
- Comandos imperativos (arrancar tracking, cambiar idioma) → llamada directa.
- Sucesos puntuales (video terminó, usuario tocó Next) → EventBus.
- Estado continuo (posición del usuario, estado del tour, POI cercano) → `@Published`.

### 4.4 AppContainer + inyección de dependencias

`App/DependencyContainer/AppContainer.swift` es el factory central. `ArTourKaminaljuyuApp`
lo instancia una vez con `.production()` e inyecta cada servicio vía `.environmentObject`:

```swift
ContentView()
    .environmentObject(container.gps)
    .environmentObject(container.language)
    .environmentObject(container.ar)
    .environmentObject(container.virtualGuide)
    .environmentObject(container.appState)
    .environmentObject(container.router)
```

`EventBus` no se inyecta como env (no es `ObservableObject`); se usa vía `EventBus.shared`.
`AppContainer.mock()` está definido en el target de pruebas (`MockServices.swift`).

Lugares donde se usa `.shared` en vez de `@EnvironmentObject`:
- `ARViewController` y `BackConfirmationView` — UIKit, el env de SwiftUI no fluye a UIViewController.
- `LocalizedStrings.get(key)` — helper estático.
- Implementación interna de `VirtualGuideModuleInterface` — lee `GPSModuleInterface.shared`,
  `LanguageService.shared` y `AppStateManager.shared`.

### 4.5 AppStateManager — estado del tour

`AppStateManager.shared` (`ObservableObject`) es la fuente autoritativa del estado del tour
(`AppState`: `.idle` / `.inTour(activePOIId:)` / `.completed`), separado del estado de
navegación (`AppRouter`). Expone `startTour()`, `completeTour()`, `reset()` y `setActivePOI()`;
este último no tiene llamadores: el POI activo lo lleva el GPSModule (`currentTargetPOI`,
`nearestPOI`).

Flujo del tour:

1. Usuario toca "Iniciar" en TourControls → `ContentView.onStartTour`:
   - `appState.startTour()` → `currentState = .inTour(activePOIId: nil)`
   - `gps.startTour()` (inicia TourManager en GPSModule)
   - `router.navigateTo(.guidedTour)`
2. GuidedTourOverlay monta → `.onAppear`:
   - `guideVM.playIntroSequence()` (encola Datos generales + Datos arqueológicos)
   - `guideVM.start()` se suscribe a EventBus + AppState + GPS
3. VirtualGuide observa `AppStateManager.$currentState`, ve `.inTour` y encola
   Indicación flecha después de los intros.
4. Usuario camina; la proximidad dispara videos según la distancia.
5. Usuario en AR toca Next → ARModule publica `.nextPOIRequested`; GPSModule avanza la ruta
   y VirtualGuide limpia la cola.
6. Usuario en el último POI o finaliza → `.tourEndRequested` → VirtualGuide reproduce Despedida.
7. Despedida termina → VirtualGuide publica `.tourEndCompleted`:
   - `appState.completeTour()` → `currentState = .completed`
   - `gps.stopTour()`
   - `router.navigateTo(.menu)`

### 4.6 AppRouter — navegación

`AppRouter.shared` (`currentRoute: AppRoute` = `.menu` / `.tourControls` / `.guidedTour`)
maneja las rutas principales. `.instructions` y `.terms` se controlan con `@State` locales
en `ContentView` (ver §7.7).

## 5. Idioma y contenido multimedia

- `LanguageService` mantiene el idioma activo (`"ES"` / `"EN"`, por defecto `"ES"`) durante
  la sesión. Solo se cambia desde `MainMenuView`, antes de iniciar el tour. No se persiste.
- `LocalizedStrings` contiene 52 claves de texto por idioma (mismo conjunto en ES y EN).
- Videos: 17 `.mov` por idioma en `LanguageModule/Resources/{Spanish,English}/` (16 del guía
  virtual + 1 de bienvenida). HEVC con canal alfa (fondo removido).
- La selección del video por idioma la hace `VirtualGuideModuleInterface` (diccionario
  `videoLocalizations`, 16 entradas con variante ES y EN). Las transcripciones ES/EN
  están en `VideoTranscripts.swift`. El video de bienvenida lo maneja `MainMenuView`.
- `LanguageService.videoPath()` existe pero solo lo usan las pruebas.
- Los `.mp4` en `Resources/Spanish/` son sources pre-procesamiento no referenciados por el
  código (ver §7.9).

Convención de nombres migrada de Android `strings.xml`: `poi_[nombre]_title`,
`poi_[nombre]_findings`, `poi_[nombre]_function`.

## 6. Pruebas

Framework: Swift Testing (`ArTourKaminaljuyuTests/`).

| Archivo | Pruebas | Estado conocido |
|---|---|---|
| `LanguageServiceTests.swift` | 8 | Pasan |
| `LocalizedStringsTests.swift` | 5 | Pasan |
| `AppStateManagerTests.swift` | 5 | Pasan |
| `EventBusTests.swift` | 3 | Pasan |
| `TourMockTests.swift` (con mocks) | 2 | Pasan |
| `FinalIntegrationTests.swift` | 10 | Sin confirmar |
| `ArTourKaminaljuyuTests.swift` | 1 | Placeholder vacío |

- Las pruebas de singletons usan delays para evitar race conditions entre suites paralelas.
- `TESTS_README.md` está desactualizado (indica 35 pruebas y menciona archivos que no existen).
- La carpeta contiene copias de `LanguageService.swift` y `LocalizedStrings.swift`.
- GPSModule, ARModule y VirtualGuideModule no tienen pruebas automatizadas; se validaron
  manualmente en dispositivo.

## 7. Deuda técnica conocida

### 7.1 Coordenadas de POIs inconsistentes

- Los 4 primeros POIs (`informacion_inicial`, `monticulo_6`, `acropolis`, `monticulo_3`)
  tienen coordenadas en `(14.60x, -90.48x)`, lejos del resto del sitio.
- Los otros 7 POIs (`monticulo_5`, `_7`, `_8`, `_12`, `palangana`, `_14`, `_13`) están en
  `(14.63x, -90.54x)`, coherentes con los conectores de `RouteConfig`.
- Pendiente de curaduría de datos (GPSModule).

### 7.2 `AppConfig.tourStartLatitude/Longitude` no coincide con el sitio

Valor actual `(14.6748361, -90.5520308)`, fuera del parque. Es intencional para pruebas fuera
del sitio (ver §9).

### 7.3 `GeoMath` + `GeoUtils` duplican Haversine

Dos implementaciones de Haversine + bearing en `GPSModule/Services/GeoMath.swift` y
`GPSModule/Navigation/GeoUtils.swift`. `ProximityService`, `TourManager`, `RouteNavigator` y
`RouteConfig` usan `GeoUtils`; nada usa `GeoMath`.

### 7.4 `ARViewController` concentra muchas responsabilidades

Mezcla setup de escena, gestos, UI programática, modal de info, suscripción a GPS/EventBus,
máquina de estado local (`currentPOIIndex`, `hasPlacedModel`), `ARSessionDelegate` y
`BackConfirmationView` embebido. Descomposición posible: `ARSessionController`,
`ARTourController`, `ARControlsView`, `ARInfoSheet` y un `ARViewController` delgado.

### 7.5 `VirtualGuideModuleInterface` como facade grande

Concentra la cola de videos, la máquina de estados de proximidad, AVPlayer, transcripciones y
configuración de audio. Descomposición posible: `VideoPlaybackService`, `VideoQueueManager`,
`ProximityPlaybackController`, `TranscriptService` y una interfaz delgada que los orquesta.

### 7.6 Espera de 300 ms en `ContentView.onFinalize`

```swift
onFinalize: {
    router.navigateTo(.guidedTour)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        EventBus.shared.publish(.tourEndRequested)
    }
}
```

El delay compensa que `GuidedTourOverlay` monte y `guideVM.start()` se suscriba antes de
publicar el evento. Una alternativa sin dependencia de tiempo sería pasar un flag a
`GuidedTourOverlay` para que dispare Despedida al montar en modo finalize.

### 7.7 `AppRouter` con navegación fragmentada

`AppRoute` cubre solo `.menu` / `.tourControls` / `.guidedTour`. `InstructionsView` y
`TermsView` usan `@State` locales en ContentView; `SplashView` usa `@State isLoading`;
`.freeTour` no tiene case (modal Coming Soon).

### 7.8 `.languageChanged` sin suscriptores

`LanguageService.setLanguage()` publica `.languageChanged`, pero ningún módulo lo escucha.

### 7.9 Archivos `.mp4` sin uso en `Resources/Spanish/`

Versiones `.mp4` de varios videos que el código no referencia; aumentan el tamaño del bundle.

## 8. Entorno de desarrollo

- El proyecto usa CocoaPods (Google Maps); se abre desde `.xcworkspace`.
- La API key de Google Maps está en `Secrets.xcconfig` (gitignored); plantilla en
  `Secrets.xcconfig.example`.
- AR requiere dispositivo físico (no funciona en simulador).
- Procesamiento de video offline: Python (numpy, PIL, scipy) + ffmpeg + `avconvert` para
  HEVC con canal alfa.

## 9. Decisiones de diseño intencionales

- **`ARModuleView()` siempre presente en el `ZStack` root de ContentView** (no lazy-loaded).
  `ARWorldTrackingConfiguration` tarda 3-5 s en preparar; precargarlo desde el splash elimina
  esa espera al iniciar el tour. A cambio, la cámara está activa desde el splash.
- **`AppConfig.tourStartLatitude/Longitude` = (14.6748361, -90.5520308)** — coordenada de
  desarrollo para probar `TourManager.startTour()` sin ir al sitio.
- **Sin persistencia** (idioma, progreso del tour). Uso primario: visita única al parque.
- **Un solo target de Xcode**, no Swift Packages separados.
- **`.languageChanged` se publica sin suscriptores**; el mecanismo queda disponible para
  consumidores futuros.
- **`EventBus` se usa para notificaciones discretas**; el estado continuo (`AppState`,
  `tourState`, `userLocation`) se propaga vía `@Published`.
- **`ARModule` publica en el `EventBus` pero no se suscribe**; reacciona al estado del tour
  observando `GPSModuleInterface.$tourState`.
- **`AppStateManager.startTour()` no publica al EventBus**; los consumidores observan
  `$currentState`.

## 10. Trabajo futuro

- Pruebas automatizadas para GPSModule, ARModule y VirtualGuideModule con mocks.
- Descomponer `ARViewController` (§7.4) y `VirtualGuideModuleInterface` (§7.5).
- Consolidar `GeoMath` + `GeoUtils` (§7.3).
- Expandir `AppRouter` con `.instructions`, `.terms`, `.freeTour`, `.splash` (§7.7).
- Reemplazar la espera de 300 ms en `onFinalize` (§7.6).
- Centralizar la paleta de colores hex en un `AppColors`.
- Implementación real de Tour Libre (hoy es placeholder con modal Coming Soon).
- Persistencia del idioma.
- Limpieza de `.mp4` sin uso (§7.9).

---

Última revisión: octubre 2026 (branch `refactor-arq`).
