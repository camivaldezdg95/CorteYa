# CorteYa — Sistema de gestión de turnos para peluquerías

Prototipo desarrollado como Trabajo Final de Graduación de la Licenciatura en Informática (Universidad Siglo 21).

CorteYa permite a una peluquería registrar clientes y profesionales, reservar, modificar, confirmar, cancelar y finalizar turnos, consultar la agenda y el historial de atenciones, y obtener un reporte de ocupación por profesional. Toda la lógica de negocio reside en la base de datos (PL/SQL), de modo que las reglas se cumplen sin importar desde dónde se opere.

**Autora:** Camila Valdez De Grandis

---

## Tecnologías

| Componente | Versión |
|---|---|
| Oracle Database Express Edition | 21c |
| Oracle APEX | 26.1 |
| Oracle REST Data Services (ORDS) | 24 o superior |
| Java (requerido por ORDS) | 17 o superior |

---

## Estructura del repositorio

| Archivo | Contenido |
|---|---|
| `00_crear_usuario.sql` | Creación del esquema `CORTEYA` y sus privilegios |
| `01_tablas.sql` | Tablas: CLIENTE, PROFESIONAL, SERVICIO, TURNO, DISPONIBILIDAD y AUDITLOG |
| `02_vistas.sql` | Vistas de agenda, turnos activos, historial y ocupación |
| `03_paquete_pkg_turnos.sql` | Paquete `PKG_TURNOS`: reglas de negocio |
| `04_procedimientos_funciones.sql` | Procedimientos y función de acceso que delegan en el paquete |
| `05_trigger_auditoria.sql` | Trigger que registra cada cambio en AUDITLOG |
| `06_datos_prueba.sql` | Datos de ejemplo (los turnos se crean con fechas futuras) |
| `apex/f100.sql` | Exportación de la aplicación APEX (ID 100) |

---

## Instalación

### 1. Crear el esquema

Conectarse como **SYSTEM** a la PDB `XEPDB1` (por ejemplo, desde SQL Developer con *Service name* `XEPDB1`), reemplazar `<CLAVE>` en `00_crear_usuario.sql` y ejecutarlo.

### 2. Crear los objetos de la base

Conectarse como **CORTEYA** y ejecutar los scripts **en orden**:

```
01_tablas.sql
02_vistas.sql
03_paquete_pkg_turnos.sql
04_procedimientos_funciones.sql
05_trigger_auditoria.sql
06_datos_prueba.sql
```

En SQL Developer: abrir cada archivo y ejecutarlo con **F5** (*Run Script*). En SQL\*Plus: `@01_tablas.sql`, etc.

Para verificar que todo compiló, la siguiente consulta no debe devolver filas:

```sql
SELECT name, type, line, text FROM user_errors;
```

### 3. Crear el workspace en APEX

1. Ingresar a la administración de APEX (`http://localhost:8080/ords/apex_admin`).
2. **Manage Workspaces → Create Workspace**: nombre `CORTEYA`, esquema existente `CORTEYA`.

### 4. Importar la aplicación

1. Ingresar al workspace `CORTEYA`.
2. **App Builder → Import**, seleccionar `apex/f100.sql`.
3. Instalar con **Application ID 100** y **Parsing Schema CORTEYA**.

### 5. Crear los usuarios y asignar roles

1. **Administration → Manage Users and Groups → Create User**: crear los usuarios de la aplicación (por ejemplo `RECEPCION` y `PROFESIONAL`).
2. En la aplicación: **Shared Components → Application Access Control → Add User Role Assignment**, y asignar a cada usuario su rol.

| Rol | Acceso |
|---|---|
| ADMINISTRADOR | Todas las páginas, incluidas Profesionales y Reporte de ocupación |
| RECEPCIONISTA | Agenda, turnos, clientes e historial de atenciones |
| PROFESIONAL | Agenda y turnos (registro de finalización) |

### 6. Iniciar ORDS y abrir la aplicación

```
java -jar <ruta_ords>\ords.war --config <ruta_config_ords> serve --apex-images <ruta_apex>\images
```

Con ORDS en ejecución, la aplicación queda disponible en:

```
http://localhost:8080/ords/r/corteya/corteya/
```

> La base de datos debe estar iniciada (servicio de Windows **OracleServiceXE**) antes de arrancar ORDS.

---

## Reglas de negocio

Todas las operaciones sobre turnos pasan por `PKG_TURNOS`. Las validaciones devuelven estos códigos:

| Código | Situación |
|---|---|
| -20001 | El horario se superpone con otro turno del profesional (considera la duración del servicio) |
| -20002 | El turno no existe |
| -20003 | Solo se confirman turnos PENDIENTES |
| -20004 | No se puede cancelar un turno finalizado o ya cancelado |
| -20005 | Solo se finalizan turnos PENDIENTES o CONFIRMADOS |
| -20006 | El turno queda fuera del horario de atención del profesional |
| -20007 | Fecha u hora anteriores al momento actual |
| -20008 | Profesional o servicio inexistente |
| -20009 | Hora con formato inválido (se espera HH:MI) |
| -20010 | Estado de destino no permitido |
| -20011 | Solo se modifican turnos PENDIENTES o CONFIRMADOS |
| -20012 | Los turnos no se eliminan: se cancelan (validación de la página APEX) |

Las reservas simultáneas para un mismo profesional se procesan de a una mediante un bloqueo de fila (`SELECT … FOR UPDATE`), lo que impide que dos operadores asignen el mismo horario al mismo tiempo.

### Ciclo de vida de un turno

| Estado actual | Puede pasar a |
|---|---|
| PENDIENTE | CONFIRMADO, CANCELADO o FINALIZADO |
| CONFIRMADO | CANCELADO o FINALIZADO |
| CANCELADO | — (estado final) |
| FINALIZADO | — (estado final) |

Los turnos PENDIENTES o CONFIRMADOS pueden reprogramarse sin cambiar de estado. Cada alta, cambio de estado y reprogramación queda registrado en `AUDITLOG` con el usuario que la realizó.
