-- ============================================================
-- CorteYa - Sistema de Gestión de Turnos para Peluquerías
-- Script 07: Paquete PL/SQL - PKG_TURNOS
-- Base de datos: Oracle 21c XE - Schema: CORTEYA
-- ============================================================

-- ESPECIFICACIÓN DEL PAQUETE
CREATE OR REPLACE PACKAGE PKG_TURNOS AS

    -- Reservar un nuevo turno
    PROCEDURE RESERVAR_TURNO (
        p_id_cliente     IN NUMBER,
        p_id_profesional IN NUMBER,
        p_id_servicio    IN NUMBER,
        p_fecha_hora     IN DATE,
        p_hora_inicio    IN VARCHAR2,
        p_observaciones  IN VARCHAR2 DEFAULT NULL
    );

    -- Confirmar un turno pendiente
    PROCEDURE CONFIRMAR_TURNO (
        p_id_turno IN NUMBER
    );

    -- Cancelar un turno
    PROCEDURE CANCELAR_TURNO (
        p_id_turno      IN NUMBER,
        p_observacion   IN VARCHAR2 DEFAULT NULL
    );

    -- Finalizar un turno (marcar como atendido)
    PROCEDURE FINALIZAR_TURNO (
        p_id_turno      IN NUMBER,
        p_observacion   IN VARCHAR2 DEFAULT NULL
    );

    -- Verificar disponibilidad de un profesional
    FUNCTION VERIFICAR_DISPONIBILIDAD (
        p_id_profesional IN NUMBER,
        p_fecha_hora     IN DATE
    ) RETURN BOOLEAN;

END PKG_TURNOS;
/

-- CUERPO DEL PAQUETE
CREATE OR REPLACE PACKAGE BODY PKG_TURNOS AS

    -- --------------------------------------------------------
    -- RESERVAR_TURNO
    -- --------------------------------------------------------
    PROCEDURE RESERVAR_TURNO (
        p_id_cliente     IN NUMBER,
        p_id_profesional IN NUMBER,
        p_id_servicio    IN NUMBER,
        p_fecha_hora     IN DATE,
        p_hora_inicio    IN VARCHAR2,
        p_observaciones  IN VARCHAR2 DEFAULT NULL
    ) AS
        v_disponible BOOLEAN;
    BEGIN
        v_disponible := VERIFICAR_DISPONIBILIDAD(p_id_profesional, p_fecha_hora);

        IF NOT v_disponible THEN
            RAISE_APPLICATION_ERROR(-20001, 'El profesional no está disponible en ese horario.');
        END IF;

        INSERT INTO TURNO (ID_CLIENTE, ID_PROFESIONAL, ID_SERVICIO, FECHA_HORA, HORA_INICIO, ESTADO, OBSERVACIONES)
        VALUES (p_id_cliente, p_id_profesional, p_id_servicio, p_fecha_hora, p_hora_inicio, 'PENDIENTE', p_observaciones);

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END RESERVAR_TURNO;

    -- --------------------------------------------------------
    -- CONFIRMAR_TURNO
    -- --------------------------------------------------------
    PROCEDURE CONFIRMAR_TURNO (
        p_id_turno IN NUMBER
    ) AS
        v_estado VARCHAR2(20);
    BEGIN
        SELECT ESTADO INTO v_estado FROM TURNO WHERE ID_TURNO = p_id_turno;

        IF v_estado != 'PENDIENTE' THEN
            RAISE_APPLICATION_ERROR(-20003, 'Solo se pueden confirmar turnos en estado PENDIENTE.');
        END IF;

        UPDATE TURNO SET ESTADO = 'CONFIRMADO' WHERE ID_TURNO = p_id_turno;
        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20002, 'No existe un turno con el ID especificado.');
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END CONFIRMAR_TURNO;

    -- --------------------------------------------------------
    -- CANCELAR_TURNO
    -- --------------------------------------------------------
    PROCEDURE CANCELAR_TURNO (
        p_id_turno    IN NUMBER,
        p_observacion IN VARCHAR2 DEFAULT NULL
    ) AS
        v_estado VARCHAR2(20);
    BEGIN
        SELECT ESTADO INTO v_estado FROM TURNO WHERE ID_TURNO = p_id_turno;

        IF v_estado = 'FINALIZADO' THEN
            RAISE_APPLICATION_ERROR(-20004, 'No se puede cancelar un turno ya finalizado.');
        END IF;

        UPDATE TURNO
        SET ESTADO = 'CANCELADO',
            OBSERVACIONES = NVL(p_observacion, OBSERVACIONES)
        WHERE ID_TURNO = p_id_turno;

        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20002, 'No existe un turno con el ID especificado.');
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END CANCELAR_TURNO;

    -- --------------------------------------------------------
    -- FINALIZAR_TURNO
    -- --------------------------------------------------------
    PROCEDURE FINALIZAR_TURNO (
        p_id_turno    IN NUMBER,
        p_observacion IN VARCHAR2 DEFAULT NULL
    ) AS
        v_estado VARCHAR2(20);
    BEGIN
        SELECT ESTADO INTO v_estado FROM TURNO WHERE ID_TURNO = p_id_turno;

        IF v_estado NOT IN ('PENDIENTE', 'CONFIRMADO') THEN
            RAISE_APPLICATION_ERROR(-20005, 'Solo se pueden finalizar turnos en estado PENDIENTE o CONFIRMADO.');
        END IF;

        UPDATE TURNO
        SET ESTADO = 'FINALIZADO',
            OBSERVACIONES = NVL(p_observacion, OBSERVACIONES)
        WHERE ID_TURNO = p_id_turno;

        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20002, 'No existe un turno con el ID especificado.');
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END FINALIZAR_TURNO;

    -- --------------------------------------------------------
    -- VERIFICAR_DISPONIBILIDAD
    -- --------------------------------------------------------
    FUNCTION VERIFICAR_DISPONIBILIDAD (
        p_id_profesional IN NUMBER,
        p_fecha_hora     IN DATE
    ) RETURN BOOLEAN AS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO v_count
        FROM TURNO
        WHERE ID_PROFESIONAL = p_id_profesional
          AND FECHA_HORA     = p_fecha_hora
          AND ESTADO NOT IN ('CANCELADO');

        RETURN v_count = 0;
    END VERIFICAR_DISPONIBILIDAD;

END PKG_TURNOS;
/
