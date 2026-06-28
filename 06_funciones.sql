-- ============================================================
-- CorteYa - Sistema de Gestión de Turnos para Peluquerías
-- Script 06: Funciones PL/SQL
-- Base de datos: Oracle 21c XE - Schema: CORTEYA
-- ============================================================

-- FUNCIÓN: FN_TURNO_DISPONIBLE
-- Retorna 'S' si el profesional está disponible en esa fecha/hora, 'N' si no
CREATE OR REPLACE FUNCTION FN_TURNO_DISPONIBLE (
    p_id_profesional IN NUMBER,
    p_fecha_hora     IN DATE
) RETURN VARCHAR2 AS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM TURNO
    WHERE ID_PROFESIONAL = p_id_profesional
      AND FECHA_HORA     = p_fecha_hora
      AND ESTADO NOT IN ('CANCELADO');

    IF v_count = 0 THEN
        RETURN 'S';
    ELSE
        RETURN 'N';
    END IF;
END FN_TURNO_DISPONIBLE;
/

-- FUNCIÓN: FN_CONTAR_TURNOS_CLIENTE
-- Retorna la cantidad total de turnos de un cliente
CREATE OR REPLACE FUNCTION FN_CONTAR_TURNOS_CLIENTE (
    p_id_cliente IN NUMBER
) RETURN NUMBER AS
    v_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM TURNO
    WHERE ID_CLIENTE = p_id_cliente;

    RETURN v_count;
END FN_CONTAR_TURNOS_CLIENTE;
/

-- FUNCIÓN: FN_ULTIMO_TURNO_CLIENTE
-- Retorna la fecha del último turno atendido de un cliente
CREATE OR REPLACE FUNCTION FN_ULTIMO_TURNO_CLIENTE (
    p_id_cliente IN NUMBER
) RETURN DATE AS
    v_fecha DATE;
BEGIN
    SELECT MAX(FECHA_HORA)
    INTO v_fecha
    FROM TURNO
    WHERE ID_CLIENTE = p_id_cliente
      AND ESTADO = 'FINALIZADO';

    RETURN v_fecha;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
END FN_ULTIMO_TURNO_CLIENTE;
/
