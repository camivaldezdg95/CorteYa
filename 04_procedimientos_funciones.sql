-- ============================================================
-- CorteYa - Script 04: Procedimientos y función de acceso
-- ============================================================

-- No contienen lógica propia: delegan en PKG_TURNOS para que las
-- reglas de negocio existan en un único lugar.

CREATE OR REPLACE PROCEDURE SP_RESERVAR_TURNO (
    p_id_cliente     IN NUMBER,
    p_id_profesional IN NUMBER,
    p_id_servicio    IN NUMBER,
    p_fecha_hora     IN DATE,
    p_hora_inicio    IN VARCHAR2,
    p_observaciones  IN VARCHAR2 DEFAULT NULL
) AS
BEGIN
    PKG_TURNOS.RESERVAR_TURNO(p_id_cliente, p_id_profesional, p_id_servicio,
                              p_fecha_hora, p_hora_inicio, p_observaciones);
END SP_RESERVAR_TURNO;
/

-- Ya no permite asignar cualquier estado: cada transición pasa por
-- el procedimiento del paquete que aplica sus reglas.
CREATE OR REPLACE PROCEDURE SP_CAMBIAR_ESTADO_TURNO (
    p_id_turno IN NUMBER,
    p_estado   IN VARCHAR2
) AS
BEGIN
    CASE UPPER(p_estado)
        WHEN 'CONFIRMADO' THEN PKG_TURNOS.CONFIRMAR_TURNO(p_id_turno);
        WHEN 'CANCELADO'  THEN PKG_TURNOS.CANCELAR_TURNO(p_id_turno);
        WHEN 'FINALIZADO' THEN PKG_TURNOS.FINALIZAR_TURNO(p_id_turno);
        ELSE RAISE_APPLICATION_ERROR(-20010,
                 'Estado no permitido. Valores válidos: CONFIRMADO, CANCELADO, FINALIZADO.');
    END CASE;
END SP_CAMBIAR_ESTADO_TURNO;
/

-- Ahora requiere servicio y hora para poder evaluar el rango completo.
CREATE OR REPLACE FUNCTION FN_TURNO_DISPONIBLE (
    p_id_profesional IN NUMBER,
    p_id_servicio    IN NUMBER,
    p_fecha_hora     IN DATE,
    p_hora_inicio    IN VARCHAR2
) RETURN VARCHAR2 AS
BEGIN
    RETURN PKG_TURNOS.VERIFICAR_DISPONIBILIDAD(p_id_profesional, p_id_servicio,
                                               p_fecha_hora, p_hora_inicio);
END FN_TURNO_DISPONIBLE;
/
