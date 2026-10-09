-- ============================================================
-- CorteYa - Script 05: Trigger de auditoría
-- ============================================================

-- Registra en AUDITLOG cada alta, cambio de estado y reprogramación
-- de un turno, con el usuario de APEX que realizó la operación.

CREATE OR REPLACE TRIGGER TR_AUDITLOG_TURNO
AFTER INSERT OR UPDATE ON TURNO
FOR EACH ROW
DECLARE
    v_usuario VARCHAR2(100) := NVL(SYS_CONTEXT('APEX$SESSION', 'APP_USER'), USER);
BEGIN
    IF INSERTING THEN
        INSERT INTO AUDITLOG (ID_TURNO, ESTADO_ANTERIOR, ESTADO_NUEVO, USUARIO, FECHA_HORA, DETALLE)
        VALUES (:NEW.ID_TURNO, NULL, :NEW.ESTADO, v_usuario, SYSDATE, 'Alta de turno');

    ELSIF UPDATING THEN
        IF NVL(:OLD.ESTADO, '-') <> NVL(:NEW.ESTADO, '-') THEN
            INSERT INTO AUDITLOG (ID_TURNO, ESTADO_ANTERIOR, ESTADO_NUEVO, USUARIO, FECHA_HORA, DETALLE)
            VALUES (:NEW.ID_TURNO, :OLD.ESTADO, :NEW.ESTADO, v_usuario, SYSDATE, 'Cambio de estado');
        END IF;

        IF :OLD.FECHA_HORA     <> :NEW.FECHA_HORA
        OR :OLD.HORA_INICIO    <> :NEW.HORA_INICIO
        OR :OLD.ID_PROFESIONAL <> :NEW.ID_PROFESIONAL
        OR :OLD.ID_SERVICIO    <> :NEW.ID_SERVICIO THEN
            INSERT INTO AUDITLOG (ID_TURNO, ESTADO_ANTERIOR, ESTADO_NUEVO, USUARIO, FECHA_HORA, DETALLE)
            VALUES (:NEW.ID_TURNO, :OLD.ESTADO, :NEW.ESTADO, v_usuario, SYSDATE,
                    'Reprogramado: ' || TO_CHAR(:OLD.FECHA_HORA, 'DD/MM/YYYY') || ' ' || :OLD.HORA_INICIO ||
                    ' (prof. ' || :OLD.ID_PROFESIONAL || ', serv. ' || :OLD.ID_SERVICIO || ') -> ' ||
                    TO_CHAR(:NEW.FECHA_HORA, 'DD/MM/YYYY') || ' ' || :NEW.HORA_INICIO ||
                    ' (prof. ' || :NEW.ID_PROFESIONAL || ', serv. ' || :NEW.ID_SERVICIO || ')');
        END IF;
    END IF;
END;
/
