-- ============================================================
-- CorteYa - Script 02: Vistas
-- ============================================================

-- Agenda completa (RF7): base de la página "Gestión de Turnos"
CREATE OR REPLACE VIEW VW_TURNOS_COMPLETO AS
SELECT t.id_turno, t.fecha_hora, t.hora_inicio,
       c.nombre || ' ' || c.apellido AS cliente,
       p.nombre || ' ' || p.apellido AS profesional,
       s.nombre AS servicio, s.duracion_min, s.precio,
       t.estado, t.observaciones
FROM turno t
JOIN cliente     c ON t.id_cliente     = c.id_cliente
JOIN profesional p ON t.id_profesional = p.id_profesional
JOIN servicio    s ON t.id_servicio    = s.id_servicio;

-- Turnos activos (base para cancelar o modificar, RF6)
CREATE OR REPLACE VIEW VW_TURNOS_PENDIENTES AS
SELECT * FROM vw_turnos_completo
WHERE estado IN ('PENDIENTE', 'CONFIRMADO');

-- Historial de atenciones por cliente (RF9)
CREATE OR REPLACE VIEW VW_HISTORIAL_CLIENTE AS
SELECT c.id_cliente,
       c.nombre || ' ' || c.apellido AS cliente,
       c.telefono, t.fecha_hora, t.hora_inicio,
       s.nombre AS servicio,
       p.nombre || ' ' || p.apellido AS profesional,
       t.estado, t.observaciones
FROM turno t
JOIN cliente     c ON t.id_cliente     = c.id_cliente
JOIN profesional p ON t.id_profesional = p.id_profesional
JOIN servicio    s ON t.id_servicio    = s.id_servicio;

-- Reporte de ocupación por profesional y estado (RF10)
CREATE OR REPLACE VIEW VW_REPORTE_OCUPACION AS
SELECT p.nombre || ' ' || p.apellido AS profesional,
       t.estado,
       COUNT(*) AS cantidad_turnos
FROM turno t
JOIN profesional p ON t.id_profesional = p.id_profesional
GROUP BY p.nombre || ' ' || p.apellido, t.estado;
