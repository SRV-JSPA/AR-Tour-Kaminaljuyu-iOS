# AR Tour Kaminaljuyú (iOS)

Aplicación iOS de realidad aumentada para el recorrido guiado del Parque Arqueológico
Kaminaljuyú, Guatemala. Guía al visitante por los montículos del parque usando su ubicación,
muestra modelos 3D de las estructuras sobre la cámara y lo acompaña con una guía virtual en
video, en español o en inglés.

Es una migración y mejora de una versión previa para Android, desarrollada como trabajo de
graduación en la Universidad del Valle de Guatemala (2026).

## Funcionalidades

- **Tour guiado** por los puntos de interés del parque, con detección de proximidad por GPS.
- **Realidad aumentada:** modelos 3D de los montículos y una flecha que indica la dirección
  del siguiente punto.
- **Guía virtual:** videos pregrabados con subtítulos que se reproducen según la distancia
  al montículo.
- **Mapa** con la ruta del recorrido, que se puede alternar con el video del guía.
- **Español e inglés:** el idioma se elige en el menú principal y se aplica a toda la
  experiencia (textos, videos y subtítulos).
- Instrucciones de uso y términos y condiciones.

## Tecnologías

| Área | Tecnología |
|---|---|
| Lenguaje | Swift |
| Interfaz | SwiftUI (UIKit en la vista de realidad aumentada) |
| Estado y eventos | Combine |
| Ubicación | CoreLocation |
| Mapa | Google Maps SDK for iOS (CocoaPods) |
| Realidad aumentada | ARKit + SceneKit |
| Video | AVFoundation / AVKit |
| Pruebas | Swift Testing |

## Requisitos

- macOS con **Xcode 26** o superior.
- **CocoaPods** (`sudo gem install cocoapods` o `brew install cocoapods`).
- **iPhone físico con iOS 26.0 o superior.** La realidad aumentada no funciona en el simulador.
- Una **API key de Google Maps** con el SDK de Maps para iOS habilitado.

## Instalación y ejecución

1. Clonar el repositorio:

   ```bash
   git clone https://github.com/SRV-JSPA/AR-Tour-Kaminaljuyu-iOS.git
   cd AR-Tour-Kaminaljuyu-iOS/ArTourKaminaljuyu
   ```

2. Instalar las dependencias:

   ```bash
   pod install
   ```

3. Configurar la API key de Google Maps. Copiar la plantilla y reemplazar el valor:

   ```bash
   cp Secrets.xcconfig.example Secrets.xcconfig
   ```

   ```
   GOOGLE_MAPS_API_KEY = tu_api_key
   ```

   `Secrets.xcconfig` está en `.gitignore` y no debe subirse al repositorio.

4. Abrir **`ArTourKaminaljuyu.xcworkspace`** (no el `.xcodeproj`, porque las dependencias
   de CocoaPods solo se cargan desde el workspace).

5. En *Signing & Capabilities*, seleccionar un equipo de desarrollo y, si es necesario,
   cambiar el *Bundle Identifier*.

6. Conectar el iPhone, seleccionarlo como destino y ejecutar (⌘R). La primera vez, aceptar
   los permisos de cámara y ubicación.

> **Nota:** el punto de inicio del recorrido (`AppConfig.tourStartLatitude/Longitude`) está
> configurado con una coordenada de desarrollo para probar fuera del parque. Para usar la
> aplicación en el sitio, ajustarla al punto de inicio real.

## Arquitectura

La aplicación sigue una arquitectura modular en tres capas:

- **App:** punto de entrada, contenedor de dependencias (`AppContainer`), navegación
  (`AppRouter`) y pantallas.
- **Shared:** bus de eventos (`EventBus`) y estado del recorrido (`AppStateManager`).
- **Feature Modules:** GPS, realidad aumentada, guía virtual y lenguaje. Cada módulo tiene
  una interfaz pública, que es el único punto de acceso para los demás, y una parte interna
  (servicios, modelos y vistas).

Los módulos se comunican de tres formas:

| Mecanismo | Uso | Ejemplo |
|---|---|---|
| Llamada a la interfaz pública | Comandos | `gps.startTour()` |
| `EventBus` (Combine) | Sucesos puntuales | `.nextPOIRequested` cuando el usuario toca "Siguiente" |
| Observación de `@Published` | Estado continuo | `gps.$nearestPOI`, `appState.$currentState` |

La documentación detallada de la arquitectura, el flujo del recorrido, la deuda técnica y
las decisiones de diseño está en
[`ArTourKaminaljuyu/ArTourKaminaljuyu/estado.md`](ArTourKaminaljuyu/ArTourKaminaljuyu/estado.md).

## Estructura del proyecto

```
ArTourKaminaljuyu/
├── ArTourKaminaljuyu/
│   ├── App/                    ← entrada, AppContainer, AppRouter y pantallas (UICoordinator)
│   ├── ContentView.swift       ← vista raíz y orquestación del recorrido
│   ├── FeatureModules/
│   │   ├── GPSModule/
│   │   ├── ARModule/
│   │   ├── VirtualGuideModule/
│   │   └── LanguageModule/     ← textos ES/EN y videos por idioma
│   ├── Shared/                 ← EventBus, AppStateManager y modelos compartidos
│   └── estado.md               ← documentación técnica detallada
├── ArTourKaminaljuyuTests/     ← pruebas (Swift Testing)
├── Podfile
└── Secrets.xcconfig.example
```

## Pruebas

Desde Xcode: **⌘U**. Desde la terminal:

```bash
xcodebuild test \
  -workspace ArTourKaminaljuyu.xcworkspace \
  -scheme ArTourKaminaljuyu \
  -destination 'platform=iOS Simulator,name=<nombre del simulador>'
```

Las pruebas cubren el módulo de lenguaje, el bus de eventos, el estado del recorrido y el
flujo del tour con módulos simulados (*mocks*). El detalle por archivo está en
[`estado.md`](ArTourKaminaljuyu/ArTourKaminaljuyu/estado.md#6-pruebas).

## Contenido multilenguaje

- **Textos:** se definen en
  `FeatureModules/LanguageModule/Content/LocalizedStrings.swift`, con la misma clave en `"ES"`
  y en `"EN"`. Las vistas los obtienen con `LocalizedStrings.get("clave")`.
- **Videos:** se guardan en `FeatureModules/LanguageModule/Resources/Spanish/` y
  `.../English/` (`.mov` HEVC con canal alfa). Cada video nuevo debe registrarse en
  `videoLocalizations` dentro de `VirtualGuideModuleInterface.swift`, con su variante en cada
  idioma, y su transcripción en `VideoTranscripts.swift`.

## Equipo

| Integrante | Módulo |
|---|---|
| Mónica | Arquitectura, integración, módulo de lenguaje e interfaz |
| Santiago | Módulo de GPS |
| Andre Jo | Módulo de realidad aumentada |
| Gaby | Módulo de guía virtual |

Universidad del Valle de Guatemala — Facultad de Ingeniería, 2026.

## Uso de inteligencia artificial

En este proyecto se utilizó Claude (Anthropic) como herramienta de apoyo durante el
desarrollo y la documentación. Todo el contenido fue revisado y validado por el equipo.
