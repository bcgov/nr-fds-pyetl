alter session set container=DBDOCK_01;

-- CREATE USER THE identified by default;
-- GRANT CONNECT TO THE;
-- GRANT RESOURCE TO THE;
-- GRANT CREATE SESSION TO THE;
-- GRANT CREATE ANY TABLE TO THE;
-- GRANT CREATE ANY INDEX TO THE;
-- GRANT ALTER ANY TABLE TO THE;
-- GRANT CREATE ANY VIEW TO THE;

-- -- going nuclear!
-- GRANT ALL privileges to THE;


-- GRANT CREATE USER TO THE;
-- createAppUser CONSEP default dbdock_01;
CREATE USER CONSEP identified by default;
GRANT CREATE TABLE TO CONSEP;
GRANT CONNECT TO CONSEP;
GRANT RESOURCE TO CONSEP;
GRANT CREATE SESSION TO CONSEP;

