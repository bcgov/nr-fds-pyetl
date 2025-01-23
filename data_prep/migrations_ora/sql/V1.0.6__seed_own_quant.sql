
  CREATE TABLE "THE"."SPAR_FUND_SRCE_CODE" 
   (	"SPAR_FUND_SRCE_CODE" VARCHAR2(3) NOT NULL ENABLE, 
	"DESCRIPTION" VARCHAR2(120) NOT NULL ENABLE, 
	"EFFECTIVE_DATE" DATE NOT NULL ENABLE, 
	"EXPIRY_DATE" DATE NOT NULL ENABLE, 
	"UPDATE_TIMESTAMP" DATE NOT NULL ENABLE
   ) ;
  CREATE UNIQUE INDEX "THE"."SPAR_FUND_SRCE_CODE_PK" ON "THE"."SPAR_FUND_SRCE_CODE" ("SPAR_FUND_SRCE_CODE") 
  ;
ALTER TABLE "THE"."SPAR_FUND_SRCE_CODE" ADD CONSTRAINT "SPAR_FUND_SRCE_CODE_PK" PRIMARY KEY ("SPAR_FUND_SRCE_CODE")
  USING INDEX "THE"."SPAR_FUND_SRCE_CODE_PK"  ENABLE;

  CREATE TABLE "THE"."METHOD_OF_PAYMENT_CODE" 
   (	"METHOD_OF_PAYMENT_CODE" VARCHAR2(3) NOT NULL ENABLE, 
	"DESCRIPTION" VARCHAR2(120) NOT NULL ENABLE, 
	"EFFECTIVE_DATE" DATE NOT NULL ENABLE, 
	"EXPIRY_DATE" DATE NOT NULL ENABLE, 
	"UPDATE_TIMESTAMP" DATE NOT NULL ENABLE
   ) ;
  CREATE UNIQUE INDEX "THE"."METHOD_OF_PAYMENT_CODE_PK" ON "THE"."METHOD_OF_PAYMENT_CODE" ("METHOD_OF_PAYMENT_CODE") 
  ;
ALTER TABLE "THE"."METHOD_OF_PAYMENT_CODE" ADD CONSTRAINT "METHOD_OF_PAYMENT_CODE_PK" PRIMARY KEY ("METHOD_OF_PAYMENT_CODE")
  USING INDEX "THE"."METHOD_OF_PAYMENT_CODE_PK"  ENABLE;

  CREATE TABLE "THE"."AUTHORIZATION_CODE" 
   (	"AUTHORIZATION_CODE" VARCHAR2(3) NOT NULL ENABLE, 
	"DESCRIPTION" VARCHAR2(120) NOT NULL ENABLE, 
	"EFFECTIVE_DATE" DATE NOT NULL ENABLE, 
	"EXPIRY_DATE" DATE NOT NULL ENABLE, 
	"UPDATE_TIMESTAMP" DATE NOT NULL ENABLE
   ) ;
  CREATE UNIQUE INDEX "THE"."AUTHORIZATION_CODE_PK" ON "THE"."AUTHORIZATION_CODE" ("AUTHORIZATION_CODE") 
  ;
ALTER TABLE "THE"."AUTHORIZATION_CODE" ADD CONSTRAINT "AUTHORIZATION_CODE_PK" PRIMARY KEY ("AUTHORIZATION_CODE")
  USING INDEX "THE"."AUTHORIZATION_CODE_PK"  ENABLE;

  CREATE TABLE "THE"."SEEDLOT_OWNER_QUANTITY_AUDIT" 
   (	"SOQ_AUDIT_ID" NUMBER NOT NULL ENABLE, 
	"AUDIT_DATE" DATE NOT NULL ENABLE, 
	"SPAR_AUDIT_CODE" VARCHAR2(1) NOT NULL ENABLE, 
	"SEEDLOT_NUMBER" VARCHAR2(5) NOT NULL ENABLE, 
	"CLIENT_NUMBER" VARCHAR2(8) NOT NULL ENABLE, 
	"CLIENT_LOCN_CODE" VARCHAR2(2) NOT NULL ENABLE, 
	"ORIGINAL_PCT_OWNED" NUMBER(4,1), 
	"ORIGINAL_PCT_RSRVD" NUMBER(4,1), 
	"ORIGINAL_PCT_SRPLS" NUMBER(4,1), 
	"QTY_RESERVED" NUMBER(10,0), 
	"QTY_RSRVD_CMTD_PLN" NUMBER(10,0), 
	"QTY_RSRVD_CMTD_APR" NUMBER(10,0), 
	"QTY_SURPLUS" NUMBER(10,0), 
	"QTY_SRPLS_CMTD_PLN" NUMBER(10,0), 
	"QTY_SRPLS_CMTD_APR" NUMBER(10,0), 
	"AUTHORIZATION_CODE" VARCHAR2(3), 
	"METHOD_OF_PAYMENT_CODE" VARCHAR2(3), 
	"SPAR_FUND_SRCE_CODE" VARCHAR2(3), 
	"REVISION_COUNT" NUMBER(5,0), 
	 CONSTRAINT "SOQA_PK" PRIMARY KEY ("SOQ_AUDIT_ID")
  USING INDEX  ENABLE, 
	 CONSTRAINT "SOQA_AC_FK" FOREIGN KEY ("AUTHORIZATION_CODE")
	  REFERENCES "THE"."AUTHORIZATION_CODE" ("AUTHORIZATION_CODE") ENABLE, 
	 CONSTRAINT "SOQA_SFSC_FK" FOREIGN KEY ("SPAR_FUND_SRCE_CODE")
	  REFERENCES "THE"."SPAR_FUND_SRCE_CODE" ("SPAR_FUND_SRCE_CODE") ENABLE, 
	 CONSTRAINT "SOQA_MOPC_FK" FOREIGN KEY ("METHOD_OF_PAYMENT_CODE")
	  REFERENCES "THE"."METHOD_OF_PAYMENT_CODE" ("METHOD_OF_PAYMENT_CODE") ENABLE, 
	 CONSTRAINT "SOQA_SEE_FK" FOREIGN KEY ("SEEDLOT_NUMBER")
	  REFERENCES "THE"."SEEDLOT" ("SEEDLOT_NUMBER") ENABLE, 
	 CONSTRAINT "SOQA_SAC_FK" FOREIGN KEY ("SPAR_AUDIT_CODE")
	  REFERENCES "THE"."SPAR_AUDIT_CODE" ("SPAR_AUDIT_CODE") ENABLE
   ) ;

   CREATE SEQUENCE  "THE"."SOQA_SEQ"  MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 102582 CACHE 20 NOORDER  NOCYCLE  NOKEEP  NOSCALE  GLOBAL ;

  CREATE TABLE "THE"."SEEDLOT_OWNER_QUANTITY" 
   (	"SEEDLOT_NUMBER" VARCHAR2(5) NOT NULL ENABLE, 
	"CLIENT_NUMBER" VARCHAR2(8) NOT NULL ENABLE, 
	"CLIENT_LOCN_CODE" VARCHAR2(2) NOT NULL ENABLE, 
	"ORIGINAL_PCT_OWNED" NUMBER(4,1) NOT NULL ENABLE, 
	"ORIGINAL_PCT_RSRVD" NUMBER(4,1) NOT NULL ENABLE, 
	"ORIGINAL_PCT_SRPLS" NUMBER(4,1) NOT NULL ENABLE, 
	"QTY_RESERVED" NUMBER(10,0) NOT NULL ENABLE, 
	"QTY_RSRVD_CMTD_PLN" NUMBER(10,0) NOT NULL ENABLE, 
	"QTY_RSRVD_CMTD_APR" NUMBER(10,0) NOT NULL ENABLE, 
	"QTY_SURPLUS" NUMBER(10,0) NOT NULL ENABLE, 
	"QTY_SRPLS_CMTD_PLN" NUMBER(10,0) NOT NULL ENABLE, 
	"QTY_SRPLS_CMTD_APR" NUMBER(10,0) NOT NULL ENABLE, 
	"AUTHORIZATION_CODE" VARCHAR2(3), 
	"METHOD_OF_PAYMENT_CODE" VARCHAR2(3), 
	"SPAR_FUND_SRCE_CODE" VARCHAR2(3), 
	"REVISION_COUNT" NUMBER(5,0) NOT NULL ENABLE
   ) ;
  CREATE UNIQUE INDEX "THE"."SEEDLOT_OWNER_QUANTITY_PK" ON "THE"."SEEDLOT_OWNER_QUANTITY" ("SEEDLOT_NUMBER", "CLIENT_NUMBER", "CLIENT_LOCN_CODE") 
  ;
ALTER TABLE "THE"."SEEDLOT_OWNER_QUANTITY" ADD CONSTRAINT "SEEDLOT_OWNER_QUANTITY_PK" PRIMARY KEY ("SEEDLOT_NUMBER", "CLIENT_NUMBER", "CLIENT_LOCN_CODE")
  USING INDEX "THE"."SEEDLOT_OWNER_QUANTITY_PK"  ENABLE;

  CREATE OR REPLACE EDITIONABLE TRIGGER "THE"."SOQ_AOU_TRG" 
  AFTER INSERT OR UPDATE OR DELETE ON seedlot_owner_quantity
  for each row

DECLARE
  v_spar_audit_code    seedlot_owner_quantity_audit.spar_audit_code%TYPE;
BEGIN
  IF INSERTING THEN
    v_spar_audit_code := 'I';
  ELSIF UPDATING THEN
    v_spar_audit_code := 'U';
  ELSE
    v_spar_audit_code := 'D';
  END IF;

  IF INSERTING OR UPDATING THEN
    --Put the new row into the audit table
    INSERT INTO seedlot_owner_quantity_audit (
             soq_audit_id
           , audit_date
           , spar_audit_code
           , seedlot_number
           , client_number
           , client_locn_code
           , original_pct_owned
           , original_pct_rsrvd
           , original_pct_srpls
           , qty_reserved
           , qty_rsrvd_cmtd_pln
           , qty_rsrvd_cmtd_apr
           , qty_surplus
           , qty_srpls_cmtd_pln
           , qty_srpls_cmtd_apr
           , authorization_code
           , method_of_payment_code
           , spar_fund_srce_code)
         VALUES (
             soqa_seq.NEXTVAL
           , SYSDATE
           , v_spar_audit_code
           , :NEW.seedlot_number
           , :NEW.client_number
           , :NEW.client_locn_code
           , :NEW.original_pct_owned
           , :NEW.original_pct_rsrvd
           , :NEW.original_pct_srpls
           , :NEW.qty_reserved
           , :NEW.qty_rsrvd_cmtd_pln
           , :NEW.qty_rsrvd_cmtd_apr
           , :NEW.qty_surplus
           , :NEW.qty_srpls_cmtd_pln
           , :NEW.qty_srpls_cmtd_apr
           , :NEW.authorization_code
           , :NEW.method_of_payment_code
           , :NEW.spar_fund_srce_code);
  ELSE
    --DELETING: Put the last row into the audit table before deleting
    INSERT INTO seedlot_owner_quantity_audit (
             soq_audit_id
           , audit_date
           , spar_audit_code
           , seedlot_number
           , client_number
           , client_locn_code
           , original_pct_owned
           , original_pct_rsrvd
           , original_pct_srpls
           , qty_reserved
           , qty_rsrvd_cmtd_pln
           , qty_rsrvd_cmtd_apr
           , qty_surplus
           , qty_srpls_cmtd_pln
           , qty_srpls_cmtd_apr
           , authorization_code
           , method_of_payment_code
           , spar_fund_srce_code)
         VALUES (
             soqa_seq.NEXTVAL
           , SYSDATE
           , v_spar_audit_code
           , :OLD.seedlot_number
           , :OLD.client_number
           , :OLD.client_locn_code
           , :OLD.original_pct_owned
           , :OLD.original_pct_rsrvd
           , :OLD.original_pct_srpls
           , :OLD.qty_reserved
           , :OLD.qty_rsrvd_cmtd_pln
           , :OLD.qty_rsrvd_cmtd_apr
           , :OLD.qty_surplus
           , :OLD.qty_srpls_cmtd_pln
           , :OLD.qty_srpls_cmtd_apr
           , :OLD.authorization_code
           , :OLD.method_of_payment_code
           , :OLD.spar_fund_srce_code);
  END IF;
END SOQ_AOU_TRG;


/
ALTER TRIGGER "THE"."SOQ_AOU_TRG" ENABLE;
