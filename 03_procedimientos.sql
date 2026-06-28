-- ============================================================
-- CorteYa - Sistema de Gestión de Turnos para Peluquerías
-- Script 03: Procedimientos Almacenados PL/SQL
-- Base de datos: Oracle 21c XE - Schema: CORTEYA
-- ============================================================

-- PROCEDIMIENTO: SP_RESERVAR_TURNO
-- Registra un nuevo turno validando que no haya solapamiento para el mismo profesional
CREATE OR REPLACE PROCEDURE SP_RESERVAR_TURNO (
    p_id_cliente     IN NUMBER,
    p_id_profesional IN NUMBER,
    p_id_servicio    IN NUMBER,
    p_fecha_hora     IN DATE,
    p_hora_inicio    IN VARCHAR2,
    p_observaciones  IN VARCHAR2 DEFAULT NULL
) AS
    v_count NUMBER;
BEGIN
    -- Verificar disponibilidad: el profesional no debe tener otro turno en la misma fecha/hora
    SELECT COUNT(*)
    INTO v_count
    FROM TURNO
    WHERE ID_PROFESIONAL = p_id_profesional
      AND FECHA_HORA = p_fecha_hora
      AND ESTADO NOT IN ('CANCELADO');

    IF v_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'El profesional ya tiene un turno asignado en ese horario.');
    END IF;

    INSERT INTO TURNO (ID_CLIENTE, ID_PROFESIONAL, ID_SERVICIO, FECHA_HORA, HORA_INICIO, ESTADO, OBSERVACIONES)
    VALUES (p_id_cliente, p_id_profesional, p_id_servicio, p_fecha_hora, p_hora_inicio, 'PENDIENTE', p_observaciones);

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END SP_RESERVAR_TURNO;
/

-- PROCEDIMIENTO: SP_CAMBIAR_ESTADO_TURNO
-- Actualiza el estado de un turno existente
CREATE OR REPLACE PROCEDURE SP_CAMBIAR_ESTADO_TURNO (
    p_id_turno IN NUMBER,
    p_estado   IN VARCHAR2
) AS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM TURNO WHERE ID_TURNO = p_id_turno;

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20002, 'No existe un turno con el ID especificado.');
    END IF;

    UPDATE TURNO SET ESTADO = p_estado WHERE ID_TURNO = p_id_turno;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END SP_CAMBIAR_ESTADO_TURNO;
/
