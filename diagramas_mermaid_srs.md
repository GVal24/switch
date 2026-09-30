# Diagramas Mermaid del sistema Switch

Este documento contiene diagramas listos para incorporar al SRS. La implementacion actual esta compuesta por una aplicacion Flutter, una API REST Node.js/Express y PostgreSQL. **Todo el dominio (chat, reportes, propuestas de intercambio, resenas y sugerencias de esfuerzo) persiste en PostgreSQL**; no hay estructuras en memoria. La API expone 28 endpoints bajo `/api` y protege las rutas privadas con JWT.

## 1. Diagrama de contexto del sistema

```mermaid
flowchart LR
    vecino[Vecino o usuario de la comunidad]
    delegado[Delegado de institucion]
    admin[Administrador]
    gps[GPS del dispositivo]
    camara[Camara o lector QR]
    sistema((Sistema Switch))
    institucion[Instituciones comunitarias]

    vecino -->|Registro, login, voluntariado, catalogo y chat| sistema
    delegado -->|Gestion y coordinacion de cupos| sistema
    admin -->|Consulta metricas, reportes y moderacion| sistema
    camara -->|Codigo QR de presencia| sistema
    gps -->|Coordenadas de presencia| sistema
    sistema -->|Consulta y activa nexos sociales| institucion
    sistema -->|Publicaciones e intercambios| vecino
```

## 2. Diagrama de contenedores / arquitectura logica

```mermaid
flowchart TB
    subgraph cliente[Cliente movil y web]
        flutter[App Flutter\nMaterialApp y pantallas]
        servicios[Servicios Dart\nApiService y servicios de dominio]
        almacenamiento[Sesion local]
        flutter --> servicios
        flutter --> almacenamiento
    end

    subgraph backend[Backend Node.js]
        express[Express REST API\nCORS, JSON y rutas]
        auth[AuthController y AuthService]
        instituciones[InstController]
        p2p[P2PController]
        intercambios[IntercambioController]
        chat[ChatController]
        reportes[ReporteController]
        sugerencias[SugerenciaController]
        usuario[UsuarioController]
        admin[AdminController]
        jwt[Middleware auth.js\nJWT + control de rol]
        errores[Error handler]
        express --> auth
        express --> instituciones
        express --> p2p
        express --> intercambios
        express --> chat
        express --> reportes
        express --> sugerencias
        express --> usuario
        express --> admin
        express --> jwt
        express --> errores
    end

    postgres[(PostgreSQL 14+\n10 tablas)]

    servicios -->|HTTP REST /api| express
    auth --> postgres
    instituciones --> postgres
    p2p --> postgres
    intercambios --> postgres
    chat --> postgres
    reportes --> postgres
    sugerencias --> postgres
    usuario --> postgres
    admin --> postgres
```

## 3. Diagrama de despliegue

```mermaid
flowchart TB
    subgraph dispositivo[Dispositivo del usuario]
        app[Aplicacion Flutter\nAndroid, iOS o Web]
        sensores[Camara y GPS]
    end

    subgraph red[Red local o entorno de desarrollo]
        api[Servidor Node.js + Express\nPuerto 3000]
        config[Configuracion por .env\nDB_*, JWT_SECRET, GPS_VALIDACION_ACTIVA]
    end

    subgraph datos[Servidor de datos]
        db[(PostgreSQL 14+)]
    end

    app -->|HTTP JSON| api
    sensores --> app
    api --> config
    api -->|Conexion SQL| db
```

## 4. Casos de uso principales

```mermaid
flowchart LR
    usuario[Usuario autenticado]
    visitante[Visitante]
    administrador[Administrador]
    sistema((Switch))

    visitante -->|Registrarse| sistema
    visitante -->|Iniciar sesion| sistema
    usuario -->|Consultar instituciones| sistema
    usuario -->|Consultar cupos abiertos| sistema
    usuario -->|Escanear QR y validar presencia| sistema
    usuario -->|Consultar catalogo P2P| sistema
    usuario -->|Crear publicacion| sistema
    usuario -->|Sugerir correccion de nivel de esfuerzo| sistema
    usuario -->|Proponer intercambio| sistema
    usuario -->|Responder y confirmar un trueque| sistema
    usuario -->|Enviar y recibir mensajes| sistema
    usuario -->|Calificar con una resena| sistema
    usuario -->|Consultar su perfil, nivel e insignias| sistema
    usuario -->|Reportar inconveniente o usuario| sistema
    visitante -->|Registrarse como institucion| sistema
    administrador -->|Consultar estadisticas| sistema
    administrador -->|Consultar y resolver reportes| sistema
    administrador -->|Suspender o dar de baja usuario| sistema
    administrador -->|Aplicar o descartar sugerencias de esfuerzo| sistema
```

## 5. Modelo entidad-relacion

```mermaid
erDiagram
    USUARIOS ||--o{ NEXOS_SOCIALES : activa
    INSTITUCIONES ||--o{ CUPOS_NECESIDAD : ofrece
    CUPOS_NECESIDAD ||--o{ NEXOS_SOCIALES : relaciona
    INSTITUCIONES ||--o{ NEXOS_SOCIALES : registra
    USUARIOS ||--o{ PUBLICACIONES_P2P : crea
    USUARIOS ||--o{ INTERCAMBIOS : propone_como_dueno
    USUARIOS ||--o{ INTERCAMBIOS : propone_como_ofertante
    PUBLICACIONES_P2P ||--o{ INTERCAMBIOS : es_publicacion_deseada
    INTERCAMBIOS ||--o{ RESENAS : recibe
    USUARIOS ||--o{ RESENAS : escribe
    USUARIOS ||--o{ RESENAS : recibe
    USUARIOS ||--o{ SUGERENCIAS_ESFUERZO : sugiere
    PUBLICACIONES_P2P ||--o{ SUGERENCIAS_ESFUERZO : recibe

    USUARIOS {
        serial id PK
        varchar dni UK
        varchar nombre
        varchar apellido
        varchar telefono UK
        varchar password
        boolean validado_mayor_edad
        timestamp fecha_aceptacion_terminos
        varchar rol "VECINO, DELEGADO o ADMIN"
        boolean activo
        timestamp suspendido_hasta
        timestamp creado_en
    }

    INSTITUCIONES {
        serial id PK
        varchar nombre
        varchar tipo
        varchar direccion
        varchar telefono
        text descripcion
        numeric latitud
        numeric longitud
        varchar qr_codigo_hash UK
        timestamp creado_en
    }

    CUPOS_NECESIDAD {
        serial id PK
        int institucion_id FK
        varchar titulo
        text descripcion
        varchar prioridad "GENERAL, PRIORITARIA o URGENTE"
        int cupo_maximo
        int cupo_actual
        boolean activo
        timestamp creado_en
    }

    NEXOS_SOCIALES {
        serial id PK
        int usuario_id FK
        int cupo_necesidad_id FK
        int institucion_id FK
        varchar metodo_validacion "QR_GPS o APROBACION_DELEGADO"
        numeric latitud_usuario
        numeric longitud_usuario
        varchar nivel_impacto "SIMPLE, MEDIO o ALTO"
        varchar estado "ACTIVO, INACTIVO o EXPIRADO"
        timestamp fecha_activacion
        timestamp fecha_expiracion
    }

    PUBLICACIONES_P2P {
        serial id PK
        int usuario_id FK
        varchar titulo
        text descripcion
        varchar nivel_esfuerzo "SIMPLE, MEDIO o ALTO"
        varchar tipo_item "GENERAL, OBJETO o SERVICIO"
        text imagen_url
        varchar estado "Activo, Pausado o Completado"
        timestamp creado_en
    }

    INTERCAMBIOS {
        serial id PK
        int publicacion_deseada_id FK
        varchar titulo_deseado
        int dueno_id FK
        int ofertante_id FK
        varchar ofertante_nombre
        jsonb items_ofrecidos
        varchar estado "PENDIENTE, ACEPTADA, RECHAZADA o COMPLETADO"
        boolean confirmacion_dueno
        boolean confirmacion_ofertante
        timestamp creado_en
    }

    RESENAS {
        serial id PK
        int intercambio_id FK
        int autor_id FK
        int destino_id FK
        int puntaje "1 a 5"
        text comentario
        timestamp creado_en
    }

    SUGERENCIAS_ESFUERZO {
        serial id PK
        int publicacion_id FK
        int usuario_id FK
        varchar nivel_sugerido "SIMPLE, MEDIO o ALTO"
        varchar estado "PENDIENTE, APLICADA o DESCARTADA"
        timestamp creado_en
    }

    REPORTES {
        serial id PK
        varchar reportante_id "ID de usuario o vacio"
        varchar reportante_nombre
        varchar reportado_id "NULL = inconveniente general"
        varchar reportado_nombre
        text motivo
        varchar estado "PENDIENTE, DESESTIMADO, RESUELTO_BAN o RESUELTO_SUSPENSION"
        timestamp creado_en
    }

    MENSAJES_CHAT {
        serial id PK
        varchar emisor_id "ID de usuario o inst_N"
        varchar receptor_id "ID de usuario o inst_N"
        text texto
        boolean leido
        timestamp creado_en
    }
```

> `mensajes_chat` no tiene clave foranea a propósito: `emisor_id` y `receptor_id` son `VARCHAR` para admitir tanto usuarios (`"1"`) como instituciones (`"inst_1"`). Por eso no participates de la relacion `PUBLICACIONES_P2P ||--o{ MENSAJES_CHAT`. Tampoco hay relacion con `REPORTES`: sus identificadores de usuario se guardan como texto para que un reporte sobreviva al borrado del usuario.

## 6. Secuencia: registro e inicio de sesion

```mermaid
sequenceDiagram
    actor U as Usuario
    participant F as App Flutter
    participant A as API Express
    participant S as AuthService
    participant DB as PostgreSQL

    alt Registro
        U->>F: Completa datos, acepta terminos y declara mayoria de edad
        F->>A: POST /api/auth/registro
        A->>S: registrarUsuario(datos)
        S->>DB: Inserta usuario
        DB-->>S: Usuario creado
        S-->>A: Datos del usuario
        A-->>F: 201 Usuario registrado
    else Inicio de sesion
        U->>F: Ingresa DNI y contrasena
        F->>A: POST /api/auth/login
        A->>S: loginUsuario(credenciales)
        S->>DB: Busca y valida usuario
        DB-->>S: Usuario valido o error
        S-->>A: Resultado de autenticacion
        A-->>F: 200 Sesion iniciada o error
        F->>F: Guarda sesion local
    end
```

## 7. Secuencia: voluntariado, QR y nexo social

```mermaid
sequenceDiagram
    actor U as Usuario
    participant F as App Flutter
    participant A as API Express
    participant I as InstitucionModel
    participant V as VoluntariadoModel
    participant DB as PostgreSQL

    U->>F: Consulta instituciones
    F->>A: GET /api/instituciones
    A->>I: obtenerTodas()
    I->>DB: SELECT instituciones
    DB-->>I: Instituciones
    I-->>F: Lista de instituciones

    U->>F: Consulta cupos de una institucion
    F->>A: GET /api/instituciones/:institucionId/cupos
    A->>V: obtenerCuposPorInstitucion(id)
    V->>DB: Consulta cupos abiertos
    DB-->>F: Cupos disponibles

    U->>F: Escanea QR y permite obtener GPS
    F->>A: POST /api/validaciones/qr-scan
    A->>I: obtenerPorQrHash(qrCodigoHash)
    I->>DB: Busca institucion por hash
    DB-->>A: Institucion o no encontrada

    opt GPS_VALIDACION_ACTIVA=true
        A->>A: geoUtils.calcularDistanciaMetros(usuario, institucion)
        alt Distancia mayor a RADIO_MAXIMO_METROS
            A-->>F: 403 Estas lejos de la institucion
        end
    end

    A->>V: registrarNexoSocial(usuario, institucion, cupo, coordenadas)
    V->>DB: Inserta nexo (metodo QR_GPS, estado ACTIVO) y actualiza el cupo
    DB-->>A: Nexo activo con expiracion y bonus
    A-->>F: 201 Nexo Social activado
```

> La validacion por geolocalizacion es **opcional**: solo corre si `GPS_VALIDACION_ACTIVA=true` en el `.env` del backend; si esta apagado o el usuario no envia coordenadas, se omite. El radio maximo sale de `geoUtils` / `RADIO_MAXIMO_METROS`.
>
> El endpoint siempre escribe `metodo_validacion = 'QR_GPS'`. El valor `APROBACION_DELEGADO` esta permitido por el esquema y lo usan 3 filas del seed, pero **ninguna API lo genera hoy**: la aprobacion por delegado no tiene endpoint y queda como funcionalidad pendiente.

## 8. Secuencia: catalogo P2P y propuesta de switch

```mermaid
sequenceDiagram
    actor U as Usuario
    participant F as App Flutter
    participant A as API Express
    participant P as P2PController
    participant I as IntercambioController
    participant V as VoluntariadoModel
    participant C as ClasificadorEsfuerzo
    participant DB as PostgreSQL

    U->>F: Abre catalogo y aplica filtros
    F->>A: GET /api/catalogo?tipoItem&nivelEsfuerzo&busqueda
    A->>P: listarCatalogoP2P(filtros)
    P->>DB: Consulta publicaciones disponibles
    DB-->>F: Publicaciones

    U->>F: Completa nueva publicacion
    F->>A: POST /api/catalogo/publicar
    A->>V: verificarNexoSocialActivo(usuarioId)
    V->>DB: Consulta nexo activo
    alt Nexo activo
        A->>C: clasificarEsfuerzo(titulo, descripcion, tipo)
        C-->>A: Nivel calculado en el servidor
        A->>DB: Inserta publicacion P2P
        DB-->>F: 201 Publicacion creada
    else Sin nexo activo
        A-->>F: 403 Debe colaborar previamente
    end

    U->>F: Cree que el nivel estimado no coincide
    F->>A: POST /api/catalogo/:publicacionId/sugerir-esfuerzo
    A->>DB: Inserta sugerencia PENDIENTE
    DB-->>F: 201 Sugerencia registrada

    U->>F: Propone intercambio con varios objetos
    F->>A: POST /api/intercambios/proponer
    A->>I: proporSwitch(datos)
    I->>DB: Valida publicacion deseada y ofrecidos, guarda intercambio PENDIENTE
    DB-->>F: Oferta enviada

    U->>F: Responde y luego confirma el trueque
    F->>A: POST /api/intercambios/:id/responder
    A->>DB: ACEPTADA o RECHAZADA
    F->>A: POST /api/intercambios/:id/confirmar
    alt Confirman ambas partes
        A->>DB: Estado COMPLETADO y registro de resena
    end
```

## 9. Secuencia: chat y moderacion

```mermaid
sequenceDiagram
    actor U as Usuario
    actor AD as Administrador
    participant F as App Flutter
    participant A as API Express
    participant DB as PostgreSQL

    U->>F: Abre el chat desde el detalle de una publicacion o de una institucion
    F->>A: GET /api/mensajes?emisorId&receptorId
    A->>DB: Filtra mensajes entre ambos participantes
    DB-->>F: Historial del chat

    U->>F: Envia mensaje
    F->>A: POST /api/mensajes/enviar
    A->>DB: Inserta mensaje con leido = FALSE
    DB-->>F: Mensaje creado

    U->>F: Reporta un usuario o un inconveniente general
    F->>A: POST /api/reportes
    A->>DB: Inserta reporte PENDIENTE
    DB-->>F: Reporte recibido

    AD->>F: Abre dashboard
    F->>A: GET /api/admin/estadisticas
    A->>DB: Agrega usuarios, trueques, voluntariados y eficacia
    DB-->>F: Estadisticas
    AD->>F: Consulta reportes y decide una sancion
    F->>A: GET /api/admin/reportes
    F->>A: POST /api/admin/suspender o /api/admin/dar-de-baja
    A->>DB: Suspende o desactiva usuario y marca reporte resuelto
    DB-->>F: Operacion confirmada

    AD->>F: Revisa sugerencias de esfuerzo de la comunidad
    F->>A: GET /api/admin/sugerencias-esfuerzo
    F->>A: POST /api/admin/sugerencias-esfuerzo/:id/aplicar
    A->>DB: Actualiza el nivel de la publicacion y marca APLICADA
```

## 10. Estados de una publicacion P2P

```mermaid
stateDiagram-v2
    [*] --> Activo: Crear publicacion (DEFAULT)
    Activo --> Completado: Confirmar el trueque\n(intercambioModel.confirmar)
```

> El comentario de `schema.sql` admite `Activo`, `Pausado` y `Completado`, pero **solo hay una transicion implementada**: el `DEFAULT` es `Activo` al publicar, y `intercambioModel.confirmar()` ejecuta `UPDATE publicaciones_p2p SET estado = 'Completado'`. No existe endpoint ni consulta que ponga `Pausado`, asi que pausar y reactivar una publicacion es functionality pendiente. Notese tambien que esta columna **no tiene `CHECK`**: los tres valores no estan validados por la base (a diferencia de `nexos_sociales`, `reportes`, `intercambios` y `sugerencias_esfuerzo`).

## 11. Estados del nexo social

```mermaid
stateDiagram-v2
    [*] --> ACTIVO: Registrar el nexo\n(voluntariadoModel.registrarNexoSocial)
    ACTIVO --> ACTIVO: Vencimiento por fecha\n(fecha_expiracion > NOW() deja de ser valido)
```

> `schema.sql` define el `CHECK estado IN ('ACTIVO', 'INACTIVO', 'EXPIRADO')`, pero el backend **solo escribe `ACTIVO`** (valor fijo en el `INSERT`). No hay consulta que marque un nexo como `INACTIVO` ni que lo cambie a `EXPIRADO`.
>
> La caducidad no se materializa en la columna `estado`: `verificarNexoSocialActivo()` exige `estado = 'ACTIVO' AND (fecha_expiracion IS NULL OR fecha_expiracion > CURRENT_TIMESTAMP)`. Es decir, un nexo vencido sigue diciendo `ACTIVO` en la base y simplemente deja de contar. Los estados `INACTIVO` y `EXPIRADO` estan disponibles en el esquema pero hoy no se usan.
>
> La vigencia tampoco es un plazo fijo: se calcula al activar el nexo (45 días base para una necesidad General, 75 Prioritaria, 105 Urgente y 60 si la visita no apunta a una necesidad concreta), mas el bonus por esfuerzo de la necesidad (Medio +15, Alto +30) y por nivel comunitario del voluntario (nivel 3 +30, 4 +60, 5 +120).

## 12. Mapa de endpoints REST actuales

Los 28 endpoints definidos en `backend/src/routes/index.js`. Todos persisten en PostgreSQL. La columna de acceso refleja el middleware real de cada ruta.

| Metodo | Endpoint | Responsabilidad | Acceso | Persistencia |
|---|---|---|---|---|
| POST | `/api/auth/registro` | Registrar usuario | Publico | PostgreSQL |
| POST | `/api/auth/login` | Autenticar usuario y emitir JWT | Publico | PostgreSQL |
| GET | `/api/instituciones` | Listar instituciones | Publico | PostgreSQL |
| GET | `/api/instituciones/:institucionId/cupos` | Listar cupos abiertos | Publico | PostgreSQL |
| POST | `/api/instituciones/registro` | Registrar institucion con sus necesidades | Publico | PostgreSQL |
| POST | `/api/validaciones/qr-scan` | Validar QR y activar nexo social | Sesion | PostgreSQL |
| GET | `/api/catalogo` | Consultar publicaciones con filtros | Publico | PostgreSQL |
| GET | `/api/catalogo/mis-publicaciones` | Listar publicaciones propias | Sesion | PostgreSQL |
| POST | `/api/catalogo/clasificar-esfuerzo` | Previsualizar nivel de esfuerzo | Publico | Sin persistir |
| POST | `/api/catalogo/imagen` | Subir imagen de una publicacion (Multer) | Sesion | Filesystem |
| POST | `/api/catalogo/publicar` | Crear publicacion P2P (exige nexo activo) | Sesion | PostgreSQL |
| POST | `/api/catalogo/:publicacionId/sugerir-esfuerzo` | Sugerir correccion del nivel de esfuerzo | Sesion | PostgreSQL |
| GET | `/api/mensajes` | Obtener historial con un receptor | Sesion | PostgreSQL |
| POST | `/api/mensajes/enviar` | Enviar mensaje | Sesion | PostgreSQL |
| POST | `/api/intercambios/proponer` | Crear propuesta de intercambio multi-item | Sesion | PostgreSQL |
| GET | `/api/intercambios/mis-propuestas` | Listar propuestas propias | Sesion | PostgreSQL |
| POST | `/api/intercambios/:id/responder` | Aceptar o rechazar una propuesta | Sesion | PostgreSQL |
| POST | `/api/intercambios/:id/confirmar` | Confirmar trueque y opcionalmente dejar una resena | Sesion | PostgreSQL |
| POST | `/api/reportes` | Reportar usuario o inconveniente general | Sesion | PostgreSQL |
| GET | `/api/usuarios/perfil` | Perfil con nivel, puntos e insignias | Sesion | PostgreSQL |
| GET | `/api/admin/estadisticas` | Metricas de la red | Sesion + Admin | PostgreSQL |
| GET | `/api/admin/reportes` | Listar reportes pendientes | Sesion + Admin | PostgreSQL |
| POST | `/api/admin/reportes/:reporteId/desestimar` | Desestimar un reporte | Sesion + Admin | PostgreSQL |
| POST | `/api/admin/dar-de-baja` | Baja permanente de un usuario | Sesion + Admin | PostgreSQL |
| POST | `/api/admin/suspender` | Suspension temporal por N dias | Sesion + Admin | PostgreSQL |
| GET | `/api/admin/sugerencias-esfuerzo` | Listar sugerencias de esfuerzo | Sesion + Admin | PostgreSQL |
| POST | `/api/admin/sugerencias-esfuerzo/:id/aplicar` | Aplicar la sugerencia al catalogo | Sesion + Admin | PostgreSQL |
| POST | `/api/admin/sugerencias-esfuerzo/:id/descartar` | Descartar la sugerencia | Sesion + Admin | PostgreSQL |

Leyenda de acceso: **Publico** = sin token; **Sesion** = `requerirSesion` (JWT valido); **Sesion + Admin** = ademas `requerirAdmin` (rol `ADMIN`).

## Observaciones

- `schema.sql` define 10 tablas: `usuarios`, `instituciones`, `cupos_necesidad`, `nexos_sociales`, `publicaciones_p2p`, `mensajes_chat`, `reportes`, `intercambios`, `resenas` y `sugerencias_esfuerzo`. Las claves primarias son `SERIAL` (integers), no UUID.
- **No hay persistencia en memoria**: chat, reportes, intercambios, resenas y sugerencias de esfuerzo estan todos en PostgreSQL. La unica excepcion es la imagen subida con Multer, que va al filesystem (`backend/uploads/`).
- La autenticacion usa **JWT con hash de contrasenas (bcrypt)**: `POST /api/auth/login` devuelve el token y el middleware `auth.js` (`requerirSesion`, `requerirAdmin`) protege el resto. El control de rol se aplica en las 8 rutas `/api/admin/*`.
- La sesion vive en el dispositivo (`SharedPreferences` en Flutter). El login administrativo se valida contra un usuario con rol `ADMIN` del backend: **no hay contrasenas embebidas en la app**.
- `reportes` y `mensajes_chat` guardan los identificadores de usuario como `VARCHAR` y no con clave foranea, a proposito: un reporte debe sobrevivir al borrado del usuario, y el chat admite un interlocutor institucional (`inst_N`) ademas de usuarios.
- `publicaciones_p2p.estado` es la unica columna de estado **sin `CHECK`**: el esquema solo la documenta en un comentario.

## Funcionalidades del esquema que todavia no implementa la API

Diferencias encontradas al contrastar `schema.sql` con el codigo. No son errores, pero conviene no documentarlas como si funcionaran:

| Definido en el esquema | Situacion real |
|---|---|
| `publicaciones_p2p.estado = 'Pausado'` | No hay endpoint ni consulta que pause o reactive una publicacion. Solo se usa `Activo` y `Completado`. |
| `nexos_sociales.estado` `INACTIVO` / `EXPIRADO` | El backend solo inserta `ACTIVO`. La caducidad se evalua por `fecha_expiracion`, sin cambiar la columna. |
| `nexos_sociales.metodo_validacion = 'APROBACION_DELEGADO'` | Ninguna API lo genera: la aprobacion de un delegado no tiene endpoint. |
| `resenas` | Se crea una al confirmar un intercambio, pero no hay endpoint para leer las resenas individuales: solo se consultan como agregados (promedio y cantidad) en el perfil y en el detalle de la publicacion. |
