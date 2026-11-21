# AR Tour Kaminaljuyú (iOS)

## Descripción

**AR Tour Kaminaljuyú** es una aplicación iOS de realidad aumentada para el recorrido guiado
del **Parque Arqueológico Kaminaljuyú**, en la Ciudad de Guatemala.

**Problema que resuelve:** la mayoría de los montículos del parque están cubiertos o
deteriorados y no siempre hay guías disponibles, por lo que muchos visitantes recorren el
sitio sin conocer su historia ni cómo eran las estructuras. La aplicación ofrece un
recorrido autoguiado que acompaña al visitante en el propio sitio, en español o en inglés.

**Cómo funciona:**

- **Tour guiado por GPS:** la app detecta la ubicación del visitante y lo guía de un
  montículo al siguiente siguiendo la ruta del parque.
- **Realidad aumentada:** al llegar a un punto de interés, muestra sobre la cámara un modelo
  3D del montículo, y una flecha indica la dirección del siguiente punto.
- **Guía virtual:** un personaje animado presenta videos pregrabados con subtítulos
  sincronizados, que se reproducen automáticamente según la distancia al montículo.
- **Mapa** con la ruta del recorrido, que se puede alternar con el video del guía.
- **Español e inglés:** el idioma se elige en la pantalla de inicio y se aplica a toda la
  experiencia (textos, videos y subtítulos).
- Pantallas de instrucciones de uso y de términos y condiciones.

Es una migración y mejora de una versión previa para Android, desarrollada como trabajo de
graduación en equipo en la Universidad del Valle de Guatemala (2026).

### Aporte individual: Módulo de Guía Virtual

Este repositorio corresponde a mi aporte al proyecto, el **módulo de guía virtual**
(`FeatureModules/VirtualGuideModule`), que incluye:

- **`VirtualGuideModuleInterface`:** interfaz pública del módulo. Controla la reproducción
  de los videos del guía según la proximidad a cada montículo, la cola de videos de
  introducción y la habilitación del botón *Siguiente*.
- **Videos localizados:** registro de cada video en español y en inglés (`.mov` HEVC con
  canal alfa), de modo que el guía cambia de idioma junto con el resto de la app.
- **`VideoTranscripts`:** subtítulos sincronizados con tiempos de inicio y fin para cada
  video, en ambos idiomas.
- **`VirtualGuideView`:** vista que muestra al guía y sus subtítulos sobre la cámara o el
  mapa.

## Tecnologías Utilizadas

- **Swift 5**
- **SwiftUI** (UIKit en la vista de realidad aumentada)
- **Combine** — manejo de estado y eventos
- **AVFoundation / AVKit** — reproducción de video de la guía virtual
- **ARKit + SceneKit** — realidad aumentada y modelos 3D
- **CoreLocation** — ubicación GPS
- **Google Maps SDK for iOS 9.x** y **Google Places SDK 9.x** — mapa y ruta
- **CocoaPods** — gestor de dependencias
- **Xcode 26**
- **Swift Testing y XCTest** — pruebas unitarias, de integración y de rendimiento

## Requisitos Previos

- **macOS** con **Xcode 26** o superior
- **CocoaPods 1.16** o superior
- **Git**
- **iPhone físico con iOS 26.0** o superior, compatible con ARKit
  (la realidad aumentada **no funciona en el simulador**)
- **Apple ID** (gratuito o de desarrollador) para firmar e instalar la app
- **API key de Google Maps** con el *Maps SDK for iOS* habilitado

## Instalación

1. **Clonar el repositorio y entrar a la carpeta del proyecto:**

   ```bash
   git clone https://github.com/nancygmm/2026-22513-nancy-gabriela-mazariegos-molina.git
   cd 2026-22513-nancy-gabriela-mazariegos-molina/src/ArTourKaminaljuyu
   ```

2. **Instalar CocoaPods** (si no está instalado):

   ```bash
   sudo gem install cocoapods
   ```

3. **Instalar las dependencias:**

   ```bash
   pod install
   ```

   Al terminar se crea la carpeta `Pods/` y el archivo `ArTourKaminaljuyu.xcworkspace`.

4. **Configurar el entorno.** En iOS las variables de entorno se manejan con un archivo
   `.xcconfig`. Copiar la plantilla y colocar la API key de Google Maps:

   ```bash
   cp Secrets.xcconfig.example Secrets.xcconfig
   ```

   Editar `Secrets.xcconfig`:

   ```
   GOOGLE_MAPS_API_KEY = tu_api_key
   ```

   `Secrets.xcconfig` está en `.gitignore` y no se sube al repositorio.

5. **Abrir el proyecto en Xcode** (el `.xcworkspace`, no el `.xcodeproj`):

   ```bash
   open ArTourKaminaljuyu.xcworkspace
   ```

6. **Configurar la firma:** seleccionar el target `ArTourKaminaljuyu` →
   *Signing & Capabilities* → elegir un *Team*. Si el *Bundle Identifier* ya está en uso,
   cambiarlo por uno propio.

7. **Ejecutar:**
   1. Conectar el iPhone a la Mac y activar el **Modo de desarrollador**
      (*Ajustes → Privacidad y seguridad → Modo de desarrollador*).
   2. Seleccionar el iPhone como destino y presionar **⌘R** (*Product → Run*).
   3. Si aparece el aviso de desarrollador no confiable, ir a
      *Ajustes → General → VPN y gestión de dispositivos* y confiar en el certificado.
   4. Aceptar los permisos de **cámara** y **ubicación**.
   5. Elegir el idioma (ES / EN) y tocar **Tour Guiado**.

> **Nota:** el recorrido inicia solo si el usuario está a menos de 20 m de la entrada del
> parque (`AppConfig.tourStartLatitude/Longitude`, en
> `FeatureModules/GPSModule/API Layer/AppConfig.swift`). Para probar fuera del sitio, cambiar
> esa coordenada y poner `routeConnectorsEnabled` en `false`.

### Pruebas

Desde Xcode: **⌘U** (*Product → Test*). Desde la terminal, dentro de `src/ArTourKaminaljuyu`:

```bash
xcodebuild test \
  -workspace ArTourKaminaljuyu.xcworkspace \
  -scheme ArTourKaminaljuyu \
  -destination 'platform=iOS Simulator,name=<nombre del simulador>'
```

## Capturas

Disponibles en [`/capturas`](capturas/) (12 capturas).

| | |
|---|---|
| ![Captura 1](capturas/captura-01.png) | ![Captura 2](capturas/captura-02.png) |
| 1. `VirtualGuideModuleInterface`: interfaz pública del módulo de guía virtual | 2. Registro de videos localizados en español e inglés |
| ![Captura 3](capturas/captura-03.png) | ![Captura 4](capturas/captura-04.png) |
| 3. `VideoTranscripts`: subtítulos sincronizados del video "Datos generales" | 4. Subtítulos del video "Datos arqueológicos" |
| ![Captura 5](capturas/captura-05.png) | ![Captura 6](capturas/captura-06.png) |
| 5. Subtítulos del montículo C-II-13 | 6. Equivalencia de videos ES → EN y búsqueda de subtítulos por idioma |
| ![Captura 7](capturas/captura-07.png) | ![Captura 8](capturas/captura-08.png) |
| 7. Video del guía virtual en inglés (bienvenida) | 8. Video del guía virtual en español (indicación de proximidad) |
| ![Captura 9](capturas/captura-09.png) | ![Captura 10](capturas/captura-10.png) |
| 9. Subtítulos en inglés | 10. Subtítulos en inglés del montículo C-II-13 |
| ![Captura 11](capturas/captura-11.png) | ![Captura 12](capturas/captura-12.png) |
| 11. Pantalla de inicio de la app en iPhone | 12. Guía virtual durante el recorrido en el parque |

## Demo

Disponible en [`/demo/demo.mp4`](demo/demo.mp4).

## Documentación

- Informe final: [`/docs/informe_final.pdf`](docs/informe_final.pdf)

## Consentimiento Firmado

Disponible en [`/docs/consentimiento_firmado.pdf`](docs/consentimiento_firmado.pdf).

## Estructura del Repositorio

```
/2026-22513-nancy-gabriela-mazariegos-molina
├── /capturas
│   └── captura-01.png ... captura-12.png
├── /demo
│   └── demo.mp4
├── /docs
│   ├── informe_final.pdf
│   └── consentimiento_firmado.pdf
├── /src
│   ├── /ArTourKaminaljuyu
│   │   ├── /ArTourKaminaljuyu
│   │   │   ├── /App                    ← entrada, navegación y pantallas
│   │   │   ├── /Assets                 ← modelos 3D, texturas e imágenes
│   │   │   ├── /FeatureModules
│   │   │   │   ├── /ARModule
│   │   │   │   ├── /GPSModule
│   │   │   │   ├── /LanguageModule     ← textos y videos ES / EN
│   │   │   │   └── /VirtualGuideModule ← módulo de guía virtual
│   │   │   ├── /Resources              ← fuentes, ícono y video
│   │   │   └── /Shared                 ← EventBus, AppStateManager y modelos
│   │   ├── /ArTourKaminaljuyuTests     ← pruebas unitarias e integración
│   │   ├── Podfile
│   │   └── Secrets.xcconfig.example    ← plantilla de variables de entorno
│   └── /PerformanceTests               ← pruebas de rendimiento
└── README.md
```

## Autores

- Nancy Gabriela Mazariegos Molina - 22513

## Licencia

Este proyecto se distribuye bajo la licencia MIT.
