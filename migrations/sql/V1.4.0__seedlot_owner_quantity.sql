-- THE.SEEDLOT_OWNER_QUANTITY definition

-- DDL generated by DBeaver
-- WARNING: It may differ from actual native database DDL

-- Drop table

-- DROP TABLE THE.SEEDLOT_OWNER_QUANTITY;

CREATE TABLE THE.SEEDLOT_OWNER_QUANTITY (
	SEEDLOT_NUMBER VARCHAR2(5),
	CLIENT_NUMBER VARCHAR2(8),
	CLIENT_LOCN_CODE VARCHAR2(2),
	ORIGINAL_PCT_OWNED NUMBER(4,1),
	ORIGINAL_PCT_RSRVD NUMBER(4,1),
	ORIGINAL_PCT_SRPLS NUMBER(4,1),
	QTY_RESERVED NUMBER(10,0),
	QTY_RSRVD_CMTD_PLN NUMBER(10,0),
	QTY_RSRVD_CMTD_APR NUMBER(10,0),
	QTY_SURPLUS NUMBER(10,0),
	QTY_SRPLS_CMTD_PLN NUMBER(10,0),
	QTY_SRPLS_CMTD_APR NUMBER(10,0),
	AUTHORIZATION_CODE VARCHAR2(3),
	METHOD_OF_PAYMENT_CODE VARCHAR2(3),
	SPAR_FUND_SRCE_CODE VARCHAR2(3),
	REVISION_COUNT NUMBER(5,0),
	CONSTRAINT SEEDLOT_OWNER_QUANTITY_PK PRIMARY KEY (SEEDLOT_NUMBER,CLIENT_NUMBER,CLIENT_LOCN_CODE),
	CONSTRAINT SYS_C0013928 CHECK ("SEEDLOT_NUMBER" IS NOT NULL),
	CONSTRAINT SYS_C0013929 CHECK ("CLIENT_NUMBER" IS NOT NULL),
	CONSTRAINT SYS_C0013930 CHECK ("CLIENT_LOCN_CODE" IS NOT NULL),
	CONSTRAINT SYS_C0013931 CHECK ("ORIGINAL_PCT_OWNED" IS NOT NULL),
	CONSTRAINT SYS_C0013932 CHECK ("ORIGINAL_PCT_RSRVD" IS NOT NULL),
	CONSTRAINT SYS_C0013933 CHECK ("ORIGINAL_PCT_SRPLS" IS NOT NULL),
	CONSTRAINT SYS_C0013934 CHECK ("QTY_RESERVED" IS NOT NULL),
	CONSTRAINT SYS_C0013935 CHECK ("QTY_RSRVD_CMTD_PLN" IS NOT NULL),
	CONSTRAINT SYS_C0013936 CHECK ("QTY_RSRVD_CMTD_APR" IS NOT NULL),
	CONSTRAINT SYS_C0013937 CHECK ("QTY_SURPLUS" IS NOT NULL),
	CONSTRAINT SYS_C0013938 CHECK ("QTY_SRPLS_CMTD_PLN" IS NOT NULL),
	CONSTRAINT SYS_C0013939 CHECK ("QTY_SRPLS_CMTD_APR" IS NOT NULL),
	CONSTRAINT SYS_C0013940 CHECK ("REVISION_COUNT" IS NOT NULL)
);
CREATE INDEX "I2$_SEEDLOT_OWNER_QUANTITY" ON THE.SEEDLOT_OWNER_QUANTITY (SEEDLOT_NUMBER);
-- CREATE UNIQUE INDEX SEEDLOT_OWNER_QUANTITY_PK ON THE.SEEDLOT_OWNER_QUANTITY (SEEDLOT_NUMBER,CLIENT_NUMBER,CLIENT_LOCN_CODE);