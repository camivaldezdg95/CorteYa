-- ============================================================
-- CorteYa - Sistema de Gestión de Turnos para Peluquerías
-- Script 02: Triggers PL/SQL
-- Base de datos: Oracle 21c XE - Schema: CORTEYA
-- ============================================================

-- TRIGGER: TR_AUDITLOG_TURNO
-- Registra automáticamente cada INSERT o UPDATE sobre TURNO en la tabla AUDITLOG
CREATE OR REPLACE TRIGGER TR_AUDITLOG_TURNO
AFTER INSERT OR UPDATE ON TURNO
FOR EACH ROW
BEGIN
    IF INSERTING THEN
        INSERT INTO AUDITLOG (ID_TURNO, ESTADO_ANTERIOR, ESTADO_NUEVO, USUARIO, FECHA_HORA)
        VALUES (:NEW.ID_TURNO, NULL, :NEW.ESTADO, USER, SYSDATE);
    ELSIF UPDATING THEN
        IF :OLD.ESTADO != :NEW.ESTADO THEN
            INSERT INTO AUDITLOG (ID_TURNO, ESTADO_ANTERIOR, ESTADO_NUEVO, USUARIO, FECHA_HORA)
            VALUES (:NEW.ID_TURNO, :OLD.ESTADO, :NEW.ESTADO, USER, SYSDATE);
        END IF;
    END IF;
END;
/
