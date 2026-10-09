-- ============================================================
-- CorteYa - Script 06: Datos de ejemplo
-- Los turnos se cargan a través de PKG_TURNOS, de modo que pasan
-- por las mismas validaciones que la aplicación. Las fechas se
-- calculan a partir de la semana próxima, para que siempre sean
-- futuras sin importar cuándo se ejecute el script.
-- ============================================================

-- Clientes
INSERT INTO CLIENTE (NOMBRE, APELLIDO, EMAIL, TELEFONO) VALUES ('Ana',    'Martínez', 'ana.martinez@ejemplo.com',  '3874123456');
INSERT INTO CLIENTE (NOMBRE, APELLIDO, EMAIL, TELEFONO) VALUES ('Laura',  'Pérez',    'laura.perez@ejemplo.com',   '3874654321');
INSERT INTO CLIENTE (NOMBRE, APELLIDO, EMAIL, TELEFONO) VALUES ('Martín', 'Gómez',    'martin.gomez@ejemplo.com',  '3874987654');

-- Profesionales
INSERT INTO PROFESIONAL (NOMBRE, APELLIDO, EMAIL, ESPECIALIDAD) VALUES ('María',   'López',   'maria.lopez@corteya.com',   'Colorista');
INSERT INTO PROFESIONAL (NOMBRE, APELLIDO, EMAIL, ESPECIALIDAD) VALUES ('Juan',    'García',  'juan.garcia@corteya.com',   'Estilista');
INSERT INTO PROFESIONAL (NOMBRE, APELLIDO, EMAIL, ESPECIALIDAD) VALUES ('Facundo', 'Juárez',  'facundo.juarez@corteya.com','Corte y estilista');

-- Servicios
INSERT INTO SERVICIO (NOMBRE, DURACION_MIN, PRECIO) VALUES ('Corte de cabello', 30,  5000);
INSERT INTO SERVICIO (NOMBRE, DURACION_MIN, PRECIO) VALUES ('Coloración',       90, 15000);
INSERT INTO SERVICIO (NOMBRE, DURACION_MIN, PRECIO) VALUES ('Peinado',          45,  7000);

-- Disponibilidad: todos los profesionales, de lunes a sábado de 10:00 a 21:00
INSERT INTO DISPONIBILIDAD (ID_PROFESIONAL, DIA_SEMANA, HORA_DESDE, HORA_HASTA)
SELECT p.ID_PROFESIONAL, d.DIA, '10:00', '21:00'
FROM PROFESIONAL p
CROSS JOIN (SELECT LEVEL AS DIA FROM DUAL CONNECT BY LEVEL <= 6) d;

COMMIT;

-- Turnos (lunes y martes de la semana próxima)
DECLARE
    v_lunes  DATE := TRUNC(SYSDATE, 'IW') + 7;
    v_martes DATE := TRUNC(SYSDATE, 'IW') + 8;

    FUNCTION cli (p_email VARCHAR2) RETURN NUMBER IS v NUMBER;
    BEGIN SELECT id_cliente INTO v FROM cliente WHERE email = p_email; RETURN v; END;

    FUNCTION pro (p_email VARCHAR2) RETURN NUMBER IS v NUMBER;
    BEGIN SELECT id_profesional INTO v FROM profesional WHERE email = p_email; RETURN v; END;

    FUNCTION ser (p_nombre VARCHAR2) RETURN NUMBER IS v NUMBER;
    BEGIN SELECT id_servicio INTO v FROM servicio WHERE nombre = p_nombre; RETURN v; END;
BEGIN
    PKG_TURNOS.RESERVAR_TURNO(cli('ana.martinez@ejemplo.com'), pro('maria.lopez@corteya.com'),
                              ser('Coloración'), v_lunes, '10:00', 'Señado');
    PKG_TURNOS.RESERVAR_TURNO(cli('laura.perez@ejemplo.com'), pro('juan.garcia@corteya.com'),
                              ser('Corte de cabello'), v_lunes, '11:00', NULL);
    PKG_TURNOS.RESERVAR_TURNO(cli('martin.gomez@ejemplo.com'), pro('facundo.juarez@corteya.com'),
                              ser('Peinado'), v_martes, '16:30', NULL);
END;
/

-- Uno de los turnos se confirma, para que haya estados distintos
DECLARE
    v_id NUMBER;
BEGIN
    SELECT MIN(id_turno) INTO v_id FROM turno;
    PKG_TURNOS.CONFIRMAR_TURNO(v_id);
END;
/
