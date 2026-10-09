-- ============================================================
-- CorteYa - Sistema de gestión de turnos para peluquerías
-- Script 00: Creación del esquema CORTEYA
-- Ejecutar como SYSTEM (o SYS) conectado a la PDB XEPDB1.
-- Reemplazar <CLAVE> por la contraseña elegida.
-- ============================================================
CREATE USER CORTEYA IDENTIFIED BY "<CLAVE>"
  DEFAULT TABLESPACE USERS
  QUOTA UNLIMITED ON USERS;

GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW,
      CREATE PROCEDURE, CREATE TRIGGER, CREATE SEQUENCE
TO CORTEYA;
