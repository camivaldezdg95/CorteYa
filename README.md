# CorteYa — Sistema de Gestión de Turnos para Peluquerías

Sistema desarrollado como Trabajo Final de Graduación (TFG) de la Licenciatura en Informática — Universidad Siglo 21.

**Autora:** Camila Valdez De Grandis  
**Tecnologías:** Oracle Database 21c XE · Oracle APEX 26.1 · PL/SQL · ORDS

---

## 📹 Demo del sistema

[Ver video demo en YouTube](https://youtu.be/Nlu6yqNw8xU)

---

## 📁 Estructura del repositorio

```
/
├── 01_DDL_tablas.sql              — Creación de tablas
├── 02_triggers.sql                — Trigger de auditoría automática
├── 03_procedimientos.sql          — Procedimientos almacenados standalone
├── 04_datos_prueba.sql            — Datos de ejemplo para pruebas
├── 05_vistas.sql                  — Vistas del sistema
├── 06_funciones.sql               — Funciones PL/SQL
├── 07_paquete_PKG_TURNOS.sql      — Paquete PL/SQL principal
└── README.md
```

---

## ⚙️ Requisitos previos

- Oracle Database 21c XE instalado
- Oracle APEX 26.1 instalado
- Oracle REST Data Services (ORDS) configurado
- SQL Developer o SQL*Plus para ejecutar los scripts

---

## 🚀 Pasos de instalación

### 1. Iniciar los servicios de Oracle

Abrir **cmd** como administrador y ejecutar:

```bash
net start OracleServiceXE
net start OracleOraDB21Home2TNSListener
```

### 2. Conectarse a la base de datos como SYSTEM

```bash
sqlplus system/TuPassword@localhost:1521/XEPDB1
```

### 3. Crear el usuario CORTEYA

```sql
CREATE USER corteya IDENTIFIED BY TuPassword;
GRANT CONNECT, RESOURCE TO corteya;
GRANT UNLIMITED TABLESPACE TO corteya;
```

### 4. Conectarse con el usuario CORTEYA

```bash
sqlplus corteya/TuPassword@localhost:1521/XEPDB1
```

### 5. Ejecutar los scripts en orden

```sql
@01_DDL_tablas.sql
@02_triggers.sql
@03_procedimientos.sql
@04_datos_prueba.sql
@05_vistas.sql
@06_funciones.sql
@07_paquete_PKG_TURNOS.sql
```

### 6. Iniciar ORDS y acceder a APEX

```bash
C:\ords\ords-latest\bin\ords.exe --config C:\ords\config serve --apex-images C:\apex\apex_26.1_en\apex\images
```

Ingresar a: `http://localhost:8080/ords/apex`

- **Workspace:** CORTEYA  
- **Usuario:** ADMIN  
- **Contraseña:** (la configurada durante la instalación de APEX)

---

## 🗂️ Tablas del sistema

| Tabla | Descripción |
|-------|-------------|
| CLIENTE | Registro de clientes de la peluquería |
| PROFESIONAL | Profesionales del establecimiento |
| SERVICIO | Servicios ofrecidos (corte, color, etc.) |
| TURNO | Turnos reservados con estado y auditoría |
| AUDITLOG | Registro automático de cambios de estado |

---

## 👁️ Vistas

| Vista | Descripción |
|-------|-------------|
| VW_TURNOS_COMPLETO | Todos los turnos con nombres de cliente, profesional y servicio |
| VW_TURNOS_HOY | Turnos del día actual |
| VW_TURNOS_PENDIENTES | Turnos con estado PENDIENTE o CONFIRMADO |
| VW_AGENDA_PROFESIONAL | Agenda futura por profesional |
| VW_REPORTE_OCUPACION | Reporte de cantidad de turnos por profesional y estado |
| VW_HISTORIAL_CLIENTE | Historial completo de turnos por cliente |

---

## 📦 Paquete PKG_TURNOS

| Procedimiento / Función | Descripción |
|-------------------------|-------------|
| RESERVAR_TURNO | Registra un nuevo turno validando disponibilidad |
| CONFIRMAR_TURNO | Confirma un turno en estado PENDIENTE |
| CANCELAR_TURNO | Cancela un turno activo |
| FINALIZAR_TURNO | Marca un turno como atendido/finalizado |
| VERIFICAR_DISPONIBILIDAD | Retorna TRUE si el profesional está disponible |

---

## 📋 Estados del turno

```
PENDIENTE → CONFIRMADO → FINALIZADO
PENDIENTE → CANCELADO
CONFIRMADO → CANCELADO
```

---

## ⚡ Funciones standalone

| Función | Descripción |
|---------|-------------|
| FN_TURNO_DISPONIBLE | Retorna 'S'/'N' según disponibilidad del profesional |
| FN_CONTAR_TURNOS_CLIENTE | Cantidad total de turnos de un cliente |
| FN_ULTIMO_TURNO_CLIENTE | Fecha del último turno finalizado del cliente |

---

*Trabajo Final de Graduación — Licenciatura en Informática — Universidad Siglo 21 — 2026*
