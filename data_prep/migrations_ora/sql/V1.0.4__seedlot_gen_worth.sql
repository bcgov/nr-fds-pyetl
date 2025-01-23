
  CREATE TABLE "THE"."SEEDLOT_GENETIC_WORTH_AUDIT" 
   (	"SEEDLOT_GENETIC_WORTH_AUDIT_ID" NUMBER(10,0) NOT NULL ENABLE, 
	"AUDIT_DATE" DATE NOT NULL ENABLE, 
	"SPAR_AUDIT_CODE" VARCHAR2(1) NOT NULL ENABLE, 
	"SEEDLOT_NUMBER" VARCHAR2(5) NOT NULL ENABLE, 
	"GENETIC_WORTH_CODE" VARCHAR2(3) NOT NULL ENABLE, 
	"GENETIC_WORTH_RTNG" NUMBER(5,0) NOT NULL ENABLE, 
	"ENTRY_USERID" VARCHAR2(30) NOT NULL ENABLE, 
	"ENTRY_TIMESTAMP" DATE NOT NULL ENABLE, 
	"UPDATE_USERID" VARCHAR2(30) NOT NULL ENABLE, 
	"UPDATE_TIMESTAMP" DATE NOT NULL ENABLE, 
	"REVISION_COUNT" NUMBER(5,0) NOT NULL ENABLE, 
	 CONSTRAINT "SGWA_PK" PRIMARY KEY ("SEEDLOT_GENETIC_WORTH_AUDIT_ID")
  USING INDEX  ENABLE, 
	 CONSTRAINT "SGWA_GWC_FK" FOREIGN KEY ("GENETIC_WORTH_CODE")
	  REFERENCES "THE"."GENETIC_WORTH_CODE" ("GENETIC_WORTH_CODE") ENABLE, 
	 CONSTRAINT "SGWA_SAUDC_FK" FOREIGN KEY ("SPAR_AUDIT_CODE")
	  REFERENCES "THE"."SPAR_AUDIT_CODE" ("SPAR_AUDIT_CODE") ENABLE
   ) ;

   CREATE SEQUENCE  "THE"."SGWA_SEQ"  MINVALUE 1 MAXVALUE 999999999999999999999999999 INCREMENT BY 1 START WITH 8830 NOCACHE  NOORDER  NOCYCLE  NOKEEP  NOSCALE  GLOBAL ;

  CREATE TABLE "THE"."SEEDLOT_GENETIC_WORTH" 
   (	"SEEDLOT_NUMBER" VARCHAR2(5) NOT NULL ENABLE, 
	"GENETIC_WORTH_CODE" VARCHAR2(3) NOT NULL ENABLE, 
	"GENETIC_WORTH_RTNG" NUMBER(5,0) NOT NULL ENABLE, 
	"ENTRY_USERID" VARCHAR2(30) NOT NULL ENABLE, 
	"ENTRY_TIMESTAMP" DATE NOT NULL ENABLE, 
	"UPDATE_USERID" VARCHAR2(30) NOT NULL ENABLE, 
	"UPDATE_TIMESTAMP" DATE NOT NULL ENABLE, 
	"REVISION_COUNT" NUMBER(5,0) NOT NULL ENABLE
   ) ;
  CREATE UNIQUE INDEX "THE"."SEEDLOT_GENETIC_WORTH_PK" ON "THE"."SEEDLOT_GENETIC_WORTH" ("SEEDLOT_NUMBER", "GENETIC_WORTH_CODE") 
  ;
ALTER TABLE "THE"."SEEDLOT_GENETIC_WORTH" ADD CONSTRAINT "SEEDLOT_GENETIC_WORTH_PK" PRIMARY KEY ("SEEDLOT_NUMBER", "GENETIC_WORTH_CODE")
  USING INDEX "THE"."SEEDLOT_GENETIC_WORTH_PK"  ENABLE;

  CREATE OR REPLACE EDITIONABLE TRIGGER "THE"."SPR_SEEDLOT_GW_AR_IUD_TRG" 
/******************************************************************************
   Trigger: SPR_SEEDLOT_GW_AR_IUD_TRG
   Purpose: This trigger audits changes to the SEEDLOT_GENETIC_WORTH table

   Revision History
   Person               Date       Comments
   -----------------    ---------  --------------------------------
   R.A.Robb             2005-02-21 Created for PT#25601
******************************************************************************/
AFTER INSERT OR UPDATE OR DELETE ON seedlot_genetic_worth
FOR EACH ROW
DECLARE
  v_spar_audit_code    seedlot_genetic_worth_audit.spar_audit_code%TYPE;
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
    INSERT INTO seedlot_genetic_worth_audit (
             seedlot_genetic_worth_audit_id
           , audit_date
           , spar_audit_code
           , seedlot_number
           , genetic_worth_code
           , genetic_worth_rtng
           , revision_count
           , entry_userid
           , entry_timestamp
           , update_userid
           , update_timestamp)
         VALUES (
             sgwa_seq.NEXTVAL
           , SYSDATE
           , v_spar_audit_code
           , :NEW.seedlot_number
           , :NEW.genetic_worth_code
           , :NEW.genetic_worth_rtng
           , :NEW.revision_count
           , :NEW.entry_userid
           , :NEW.entry_timestamp
           , :NEW.update_userid
           , :NEW.update_timestamp);
  ELSE
    --DELETING: Put the last row into the audit table before deleting
    INSERT INTO seedlot_genetic_worth_audit (
             seedlot_genetic_worth_audit_id
           , audit_date
           , spar_audit_code
           , seedlot_number
           , genetic_worth_code
           , genetic_worth_rtng
           , revision_count
           , entry_userid
           , entry_timestamp
           , update_userid
           , update_timestamp)
         VALUES (
             sgwa_seq.NEXTVAL
           , SYSDATE
           , v_spar_audit_code
           , :OLD.seedlot_number
           , :OLD.genetic_worth_code
           , :OLD.genetic_worth_rtng
           , :OLD.revision_count
           , :OLD.entry_userid
           , :OLD.entry_timestamp
           , :OLD.update_userid
           , :OLD.update_timestamp);
  END IF;

END spr_seedlot_gw_ar_iud_trg;



/
ALTER TRIGGER "THE"."SPR_SEEDLOT_GW_AR_IUD_TRG" ENABLE;
