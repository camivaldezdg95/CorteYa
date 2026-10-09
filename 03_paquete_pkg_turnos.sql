-- ============================================================
-- CorteYa - Script 03: Paquete PKG_TURNOS (lógica de negocio del sistema)
-- ============================================================

-- Concentra todas las reglas sobre turnos: validación de horario
-- (formato, fecha futura, disponibilidad del profesional, duración del
-- servicio y solapamiento), bloqueo por concurrencia y transiciones
-- de estado. La aplicación APEX invoca exclusivamente este paquete.
--
-- Códigos de error:
--   -20001 Solapamiento con otro turno del profesional
--   -20002 Turno inexistente
--   -20003 Solo se confirman turnos PENDIENTES
--   -20004 Turno finalizado o ya cancelado
--   -20005 Solo se finalizan turnos PENDIENTES o CONFIRMADOS
--   -20006 Fuera del horario de disponibilidad del profesional
--   -20007 Fecha y hora anteriores al momento actual
--   -20008 Profesional o servicio inexistente
--   -20009 Hora con formato inválido
--   -20010 Estado de destino no permitido
--   -20011 Solo se modifican turnos PENDIENTES o CONFIRMADOS
-- ------------------------------------------------------------

CREATE OR REPLACE PACKAGE PKG_TURNOS AS

    PROCEDURE RESERVAR_TURNO (
        p_id_cliente     IN NUMBER,
        p_id_profesional IN NUMBER,
        p_id_servicio    IN NUMBER,
        p_fecha_hora     IN DATE,
        p_hora_inicio    IN VARCHAR2,
        p_observaciones  IN VARCHAR2 DEFAULT NULL
    );

    PROCEDURE MODIFICAR_TURNO (
        p_id_turno       IN NUMBER,
        p_id_profesional IN NUMBER,
        p_id_servicio    IN NUMBER,
        p_fecha_hora     IN DATE,
        p_hora_inicio    IN VARCHAR2,
        p_observacion    IN VARCHAR2 DEFAULT NULL
    );

    PROCEDURE CONFIRMAR_TURNO (p_id_turno IN NUMBER);

    PROCEDURE CANCELAR_TURNO (
        p_id_turno    IN NUMBER,
        p_observacion IN VARCHAR2 DEFAULT NULL
    );

    PROCEDURE FINALIZAR_TURNO (
        p_id_turno    IN NUMBER,
        p_observacion IN VARCHAR2 DEFAULT NULL
    );

    -- Valida un horario y lanza el error correspondiente si no es válido
    PROCEDURE VALIDAR_HORARIO (
        p_id_profesional   IN NUMBER,
        p_id_servicio      IN NUMBER,
        p_fecha_hora       IN DATE,
        p_hora_inicio      IN VARCHAR2,
        p_id_turno_excluir IN NUMBER DEFAULT NULL
    );

    -- Devuelve 'S' si el horario es válido y 'N' si no lo es (usable desde SQL y APEX)
    FUNCTION VERIFICAR_DISPONIBILIDAD (
        p_id_profesional   IN NUMBER,
        p_id_servicio      IN NUMBER,
        p_fecha_hora       IN DATE,
        p_hora_inicio      IN VARCHAR2,
        p_id_turno_excluir IN NUMBER DEFAULT NULL
    ) RETURN VARCHAR2;

END PKG_TURNOS;
/

CREATE OR REPLACE PACKAGE BODY PKG_TURNOS AS

    -- Une el día (FECHA_HORA) y la hora (HORA_INICIO) en un único DATE
    FUNCTION ARMAR_INICIO (p_fecha IN DATE, p_hora IN VARCHAR2) RETURN DATE AS
    BEGIN
        IF p_hora IS NULL OR NOT REGEXP_LIKE(p_hora, '^([01][0-9]|2[0-3]):[0-5][0-9]$') THEN
            RAISE_APPLICATION_ERROR(-20009, 'La hora debe tener el formato HH:MI (por ejemplo, 09:30).');
        END IF;
        RETURN TRUNC(p_fecha)
             + (TO_NUMBER(SUBSTR(p_hora, 1, 2)) * 60 + TO_NUMBER(SUBSTR(p_hora, 4, 2))) / 1440;
    END ARMAR_INICIO;

    -- Bloquea la fila del profesional hasta el COMMIT, de modo que dos
    -- reservas simultáneas para el mismo profesional se procesen de a una
    PROCEDURE BLOQUEAR_PROFESIONAL (p_id_profesional IN NUMBER) AS
        v_id NUMBER;
    BEGIN
        SELECT ID_PROFESIONAL INTO v_id
        FROM PROFESIONAL
        WHERE ID_PROFESIONAL = p_id_profesional
        FOR UPDATE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20008, 'El profesional indicado no existe.');
    END BLOQUEAR_PROFESIONAL;

    PROCEDURE VALIDAR_HORARIO (
        p_id_profesional   IN NUMBER,
        p_id_servicio      IN NUMBER,
        p_fecha_hora       IN DATE,
        p_hora_inicio      IN VARCHAR2,
        p_id_turno_excluir IN NUMBER DEFAULT NULL
    ) AS
        v_inicio   DATE;
        v_fin      DATE;
        v_duracion NUMBER;
        v_dia      NUMBER;
        v_count    NUMBER;
    BEGIN
        v_inicio := ARMAR_INICIO(p_fecha_hora, p_hora_inicio);

        BEGIN
            SELECT DURACION_MIN INTO v_duracion FROM SERVICIO WHERE ID_SERVICIO = p_id_servicio;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(-20008, 'El servicio indicado no existe.');
        END;

        v_fin := v_inicio + v_duracion / 1440;

        IF v_inicio < SYSDATE THEN
            RAISE_APPLICATION_ERROR(-20007, 'No se pueden registrar turnos en una fecha u hora pasada.');
        END IF;

        -- Día de la semana ISO: 1 = lunes ... 7 = domingo
        v_dia := TRUNC(v_inicio) - TRUNC(v_inicio, 'IW') + 1;

        SELECT COUNT(*) INTO v_count
        FROM DISPONIBILIDAD
        WHERE ID_PROFESIONAL = p_id_profesional
          AND DIA_SEMANA     = v_dia
          AND HORA_DESDE    <= TO_CHAR(v_inicio, 'HH24:MI')
          AND HORA_HASTA    >= TO_CHAR(v_fin,    'HH24:MI')
          AND TRUNC(v_fin)   = TRUNC(v_inicio);

        IF v_count = 0 THEN
            RAISE_APPLICATION_ERROR(-20006,
                'El turno queda fuera del horario de atención del profesional.');
        END IF;

        -- Solapamiento: dos rangos [ini, fin) se superponen si
        -- inicio_existente < fin_nuevo  y  fin_existente > inicio_nuevo
        SELECT COUNT(*) INTO v_count
        FROM TURNO t
        JOIN SERVICIO s ON s.ID_SERVICIO = t.ID_SERVICIO
        WHERE t.ID_PROFESIONAL = p_id_profesional
          AND t.ESTADO <> 'CANCELADO'
          AND (p_id_turno_excluir IS NULL OR t.ID_TURNO <> p_id_turno_excluir)
          AND TRUNC(t.FECHA_HORA) = TRUNC(v_inicio)
          AND TRUNC(t.FECHA_HORA)
              + (TO_NUMBER(SUBSTR(t.HORA_INICIO, 1, 2)) * 60 + TO_NUMBER(SUBSTR(t.HORA_INICIO, 4, 2))) / 1440
              < v_fin
          AND TRUNC(t.FECHA_HORA)
              + (TO_NUMBER(SUBSTR(t.HORA_INICIO, 1, 2)) * 60 + TO_NUMBER(SUBSTR(t.HORA_INICIO, 4, 2)) + s.DURACION_MIN) / 1440
              > v_inicio;

        IF v_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20001,
                'El horario se superpone con otro turno del profesional.');
        END IF;
    END VALIDAR_HORARIO;

    FUNCTION VERIFICAR_DISPONIBILIDAD (
        p_id_profesional   IN NUMBER,
        p_id_servicio      IN NUMBER,
        p_fecha_hora       IN DATE,
        p_hora_inicio      IN VARCHAR2,
        p_id_turno_excluir IN NUMBER DEFAULT NULL
    ) RETURN VARCHAR2 AS
    BEGIN
        VALIDAR_HORARIO(p_id_profesional, p_id_servicio, p_fecha_hora, p_hora_inicio, p_id_turno_excluir);
        RETURN 'S';
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE IN (-20001, -20006, -20007, -20008, -20009) THEN
                RETURN 'N';
            END IF;
            RAISE;
    END VERIFICAR_DISPONIBILIDAD;

    PROCEDURE RESERVAR_TURNO (
        p_id_cliente     IN NUMBER,
        p_id_profesional IN NUMBER,
        p_id_servicio    IN NUMBER,
        p_fecha_hora     IN DATE,
        p_hora_inicio    IN VARCHAR2,
        p_observaciones  IN VARCHAR2 DEFAULT NULL
    ) AS
    BEGIN
        BLOQUEAR_PROFESIONAL(p_id_profesional);
        VALIDAR_HORARIO(p_id_profesional, p_id_servicio, p_fecha_hora, p_hora_inicio);

        INSERT INTO TURNO (ID_CLIENTE, ID_PROFESIONAL, ID_SERVICIO, FECHA_HORA, HORA_INICIO, ESTADO, OBSERVACIONES)
        VALUES (p_id_cliente, p_id_profesional, p_id_servicio, TRUNC(p_fecha_hora), p_hora_inicio,
                'PENDIENTE', p_observaciones);

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END RESERVAR_TURNO;

    PROCEDURE MODIFICAR_TURNO (
        p_id_turno       IN NUMBER,
        p_id_profesional IN NUMBER,
        p_id_servicio    IN NUMBER,
        p_fecha_hora     IN DATE,
        p_hora_inicio    IN VARCHAR2,
        p_observacion    IN VARCHAR2 DEFAULT NULL
    ) AS
        v_estado VARCHAR2(20);
    BEGIN
        SELECT ESTADO INTO v_estado FROM TURNO WHERE ID_TURNO = p_id_turno FOR UPDATE;

        IF v_estado NOT IN ('PENDIENTE', 'CONFIRMADO') THEN
            RAISE_APPLICATION_ERROR(-20011, 'Solo se pueden modificar turnos PENDIENTES o CONFIRMADOS.');
        END IF;

        BLOQUEAR_PROFESIONAL(p_id_profesional);
        VALIDAR_HORARIO(p_id_profesional, p_id_servicio, p_fecha_hora, p_hora_inicio, p_id_turno);

        UPDATE TURNO
        SET ID_PROFESIONAL = p_id_profesional,
            ID_SERVICIO    = p_id_servicio,
            FECHA_HORA     = TRUNC(p_fecha_hora),
            HORA_INICIO    = p_hora_inicio,
            OBSERVACIONES  = NVL(p_observacion, OBSERVACIONES)
        WHERE ID_TURNO = p_id_turno;

        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20002, 'No existe un turno con el ID especificado.');
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END MODIFICAR_TURNO;

    PROCEDURE CONFIRMAR_TURNO (p_id_turno IN NUMBER) AS
        v_estado VARCHAR2(20);
    BEGIN
        SELECT ESTADO INTO v_estado FROM TURNO WHERE ID_TURNO = p_id_turno FOR UPDATE;

        IF v_estado <> 'PENDIENTE' THEN
            RAISE_APPLICATION_ERROR(-20003, 'Solo se pueden confirmar turnos en estado PENDIENTE.');
        END IF;

        UPDATE TURNO SET ESTADO = 'CONFIRMADO' WHERE ID_TURNO = p_id_turno;
        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20002, 'No existe un turno con el ID especificado.');
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END CONFIRMAR_TURNO;

    PROCEDURE CANCELAR_TURNO (
        p_id_turno    IN NUMBER,
        p_observacion IN VARCHAR2 DEFAULT NULL
    ) AS
        v_estado VARCHAR2(20);
    BEGIN
        SELECT ESTADO INTO v_estado FROM TURNO WHERE ID_TURNO = p_id_turno FOR UPDATE;

        IF v_estado IN ('FINALIZADO', 'CANCELADO') THEN
            RAISE_APPLICATION_ERROR(-20004, 'No se puede cancelar un turno finalizado o ya cancelado.');
        END IF;

        UPDATE TURNO
        SET ESTADO        = 'CANCELADO',
            OBSERVACIONES = NVL(p_observacion, OBSERVACIONES)
        WHERE ID_TURNO = p_id_turno;

        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20002, 'No existe un turno con el ID especificado.');
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END CANCELAR_TURNO;

    PROCEDURE FINALIZAR_TURNO (
        p_id_turno    IN NUMBER,
        p_observacion IN VARCHAR2 DEFAULT NULL
    ) AS
        v_estado VARCHAR2(20);
    BEGIN
        SELECT ESTADO INTO v_estado FROM TURNO WHERE ID_TURNO = p_id_turno FOR UPDATE;

        IF v_estado NOT IN ('PENDIENTE', 'CONFIRMADO') THEN
            RAISE_APPLICATION_ERROR(-20005, 'Solo se pueden finalizar turnos en estado PENDIENTE o CONFIRMADO.');
        END IF;

        UPDATE TURNO
        SET ESTADO        = 'FINALIZADO',
            OBSERVACIONES = NVL(p_observacion, OBSERVACIONES)
        WHERE ID_TURNO = p_id_turno;

        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20002, 'No existe un turno con el ID especificado.');
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END FINALIZAR_TURNO;

END PKG_TURNOS;
/
