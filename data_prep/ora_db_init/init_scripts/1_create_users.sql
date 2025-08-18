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
grant select any table to CONSEP ;




BEGIN
    EXECUTE IMMEDIATE 'CREATE USER "THE" IDENTIFIED BY default';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -01920 THEN -- Ignore "user already exists" error
            RAISE;
        END IF;
END;
/

-- CREATE USER "THE" IDENTIFIED BY "default"  ;
-- GRANT CREATE SESSION TO THE; -- Added this line to fix the login issue


grant select any table to THE ;
grant select on sys.dba_objects to THE;
grant READ on sys.dba_objects to THE;
grant select_catalog_role to THE;
grant execute on dbms_metadata to THE;

GRANT SELECT ANY DICTIONARY TO THE;



