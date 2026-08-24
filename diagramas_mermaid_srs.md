# Diagramas Mermaid del sistema Switch

Este documento contiene diagramas listos para incorporar al SRS. La implementacion actual esta compuesta por una aplicacion Flutter, una API REST Node.js/Express y PostgreSQL. Los endpoints de chat, reportes y propuestas de switch se mantienen actualmente en memoria dentro del servidor.

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
        admin[AdminController]
        soporte[Rutas directas\nchat, reportes y propuestas]
        errores[Error handler]
        express --> auth
        express --> instituciones
        express --> p2p
        express --> admin
        express --> soporte
        express --> errores
    end

    postgres[(PostgreSQL 14+)]
    memoria[(Memoria del proceso\nchat, reportes, ofertas y usuarios auxiliares)]

    servicios -->|HTTP REST /api| express
    auth --> postgres
    instituciones --> postgres
    p2p --> postgres
    admin --> postgres
    soporte --> memoria
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
        runtime[Memoria del proceso Node.js]
    end

    subgraph datos[Servidor de datos]
        db[(PostgreSQL 14+)]
    end

    app -->|HTTP JSON| api
    sensores --> app
    api --> runtime
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
    usuario -->|Proponer switch| sistema
    usuario -->|Enviar y recibir mensajes| sistema
    usuario -->|Reportar inconveniente o usuario| sistema
    administrador -->|Consultar estadisticas| sistema
    administrador -->|Consultar reportes| sistema
    administrador -->|Dar de baja usuario| sistema
```

## 5. Modelo entidad-relacion

```mermaid
erDiagram
    USUARIOS ||--o{ NEXOS_SOCIALES : activa
    INSTITUCIONES ||--o{ CUPOS_NECESIDAD : ofrece
    CUPOS_NECESIDAD ||--o{ NEXOS_SOCIALES : relaciona
    INSTITUCIONES ||--o{ NEXOS_SOCIALES : registra
    USUARIOS ||--o{ PUBLICACIONES_P2P : crea
    PUBLICACIONES_P2P ||--o{ MENSAJES_CHAT : recibe
    USUARIOS ||--o{ MENSAJES_CHAT : emite
    USUARIOS ||--o{ MENSAJES_CHAT : recibe

    USUARIOS {
        uuid id PK
        varchar dni UK
        varchar nombre
        varchar apellido
        varchar telefono UK
        boolean validado_mayor_edad
        timestamp fecha_aceptacion_terminos
        varchar rol
        timestamp creado_en
    }

    INSTITUCIONES {
        uuid id PK
        varchar nombre
        varchar tipo
        varchar direccion
        numeric latitud
        numeric longitud
        varchar qr_codigo_hash UK
        timestamp creado_en
    }

    CUPOS_NECESIDAD {
        uuid id PK
        uuid institucion_id FK
        varchar titulo
        text descripcion
        int cupo_maximo
        int cupo_actual
        varchar estado
        timestamp creado_en
    }

    NEXOS_SOCIALES {
        uuid id PK
        uuid usuario_id FK
        uuid cupo_necesidad_id FK
        uuid institucion_id FK
        varchar metodo_validacion
        numeric latitud_usuario
        numeric longitud_usuario
        varchar estado
        timestamp fecha_activacion
        timestamp fecha_expiracion
    }

    PUBLICACIONES_P2P {
        uuid id PK
        uuid usuario_id FK
        varchar titulo
        text descripcion
        varchar categoria
        varchar nivel_esfuerzo
        varchar tipo_item
        text imagen_url
        varchar estado
        timestamp creado_en
    }

    MENSAJES_CHAT {
        uuid id PK
        uuid publicacion_id FK
        uuid emisor_id FK
        uuid receptor_id FK
        text contenido
        boolean leido
        timestamp enviado_en
    }
```

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
    F->>A: GET /api/instituciones/{id}/cupos
    A->>V: obtenerCuposPorInstitucion(id)
    V->>DB: Consulta cupos abiertos
    DB-->>F: Cupos disponibles

    U->>F: Escanea QR y permite obtener GPS
    F->>A: POST /api/validaciones/qr-scan
    A->>I: obtenerPorQrHash(qrCodigoHash)
    I->>DB: Busca institucion por hash
    DB-->>A: Institucion o no encontrada
    A->>V: registrarNexoSocial(usuario, institucion, cupo, coordenadas)
    V->>DB: Inserta nexo social y actualiza cupo
    DB-->>A: Nexo activo con expiracion
    A-->>F: 201 Nexo Social activado
```

## 8. Secuencia: catalogo P2P y propuesta de switch

```mermaid
sequenceDiagram
    actor U as Usuario
    participant F as App Flutter
    participant A as API Express
    participant P as P2PController
    participant V as VoluntariadoModel
    participant DB as PostgreSQL
    participant M as Memoria del servidor

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
        A->>DB: Inserta publicacion P2P
        DB-->>F: 201 Publicacion creada
    else Sin nexo activo
        A-->>F: 403 Debe colaborar previamente
    end

    U->>F: Propone intercambio con varios objetos
    F->>A: POST /api/switch/proponer
    A->>M: Guarda oferta pendiente
    M-->>F: Oferta enviada
```

## 9. Secuencia: chat y moderacion

```mermaid
sequenceDiagram
    actor U as Usuario
    actor AD as Administrador
    participant F as App Flutter
    participant A as API Express
    participant M as Memoria del servidor

    U->>F: Abre chat de una publicacion
    F->>A: GET /api/chat/{emisorId}/{receptorId}
    A->>M: Filtra mensajes entre usuarios
    M-->>F: Historial del chat

    U->>F: Envia mensaje
    F->>A: POST /api/chat/enviar
    A->>M: Agrega mensaje
    opt Receptor es una institucion
        A->>M: Programa respuesta automatica
    end
    M-->>F: Mensaje creado

    U->>F: Reporta un usuario
    F->>A: POST /api/reportar-usuario
    A->>M: Crea reporte PENDIENTE
    M-->>F: Reporte recibido

    AD->>F: Abre dashboard
    F->>A: GET /api/admin/estadisticas
    A->>M: Calcula metricas auxiliares
    M-->>F: Estadisticas
    AD->>F: Consulta reportes y decide baja
    F->>A: POST /api/admin/dar-de-baja
    A->>M: Elimina usuario y marca reporte resuelto
    M-->>F: Operacion confirmada
```

## 10. Estados de una publicacion P2P

```mermaid
stateDiagram-v2
    [*] --> DISPONIBLE: Crear publicacion
    DISPONIBLE --> PAUSADO: Pausar oferta
    PAUSADO --> DISPONIBLE: Reactivar oferta
    DISPONIBLE --> FINALIZADO: Concretar intercambio
    PAUSADO --> FINALIZADO: Cerrar oferta
    FINALIZADO --> [*]
```

## 11. Estados del nexo social

```mermaid
stateDiagram-v2
    [*] --> ACTIVO: Validar QR y registrar presencia
    ACTIVO --> EXPIRADO: Pasan 30 dias
    ACTIVO --> INACTIVO: Desactivar nexo
    INACTIVO --> ACTIVO: Nueva validacion
    EXPIRADO --> ACTIVO: Nueva validacion
```

## 12. Mapa de endpoints REST actuales

| Metodo | Endpoint | Responsabilidad | Persistencia actual |
|---|---|---|---|
| POST | `/api/auth/registro` | Registrar usuario | PostgreSQL |
| POST | `/api/auth/login` | Autenticar usuario | PostgreSQL |
| GET | `/api/instituciones` | Listar instituciones | PostgreSQL |
| GET | `/api/instituciones/{id}/cupos` | Listar cupos abiertos | PostgreSQL |
| POST | `/api/validaciones/qr-scan` | Activar nexo social | PostgreSQL |
| GET | `/api/catalogo` | Consultar publicaciones | PostgreSQL |
| POST | `/api/catalogo/publicar` | Crear publicacion P2P | PostgreSQL |
| GET | `/api/chat/{emisorId}/{receptorId}` | Obtener mensajes | Memoria del servidor |
| POST | `/api/chat/enviar` | Enviar mensaje | Memoria del servidor |
| POST | `/api/switch/proponer` | Crear propuesta de intercambio | Memoria del servidor |
| GET | `/api/admin/estadisticas` | Obtener metricas | Mixta, segun controlador |
| GET | `/api/admin/reportes` | Listar reportes | Memoria del servidor |
| POST | `/api/reportar-usuario` | Crear reporte | Memoria del servidor |
| POST | `/api/admin/dar-de-baja` | Dar de baja usuario | Memoria del servidor |

## Observaciones para el SRS

- El modelo SQL define `usuarios`, `instituciones`, `cupos_necesidad`, `nexos_sociales`, `publicaciones_p2p` y `mensajes_chat`.
- El codigo actual usa estructuras en memoria para chat, reportes, propuestas de switch y usuarios auxiliares. El SRS debe describirlas como persistencia temporal mientras no exista una migracion SQL para esas entidades.
- La pantalla Flutter de acceso administrativo contiene credenciales embebidas y el backend no muestra middleware de autenticacion/autorizacion en las rutas. Para produccion, el SRS deberia incluir autenticacion segura, hash de contrasenas, sesiones o JWT y control de roles.
- El diagrama entidad-relacion representa el esquema SQL; no agrega tablas para reportes ni propuestas porque esas tablas no existen en `schema.sql`.
