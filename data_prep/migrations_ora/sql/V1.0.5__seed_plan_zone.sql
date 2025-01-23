
   CREATE SEQUENCE  "THE"."SPZA_SEQ"  MINVALUE 1 MAXVALUE 999999999999999999999999999 INCREMENT BY 1 START WITH 23488 NOCACHE  NOORDER  NOCYCLE  NOKEEP  NOSCALE  GLOBAL ;

  CREATE TABLE "THE"."SEEDLOT_PLAN_ZONE_AUDIT" 
   (	"SEEDLOT_PLAN_ZONE_AUDIT_ID" NUMBER(10,0) NOT NULL ENABLE, 
	"AUDIT_DATE" DATE NOT NULL ENABLE, 
	"SPAR_AUDIT_CODE" VARCHAR2(1) NOT NULL ENABLE, 
	"SEEDLOT_NUMBER" VARCHAR2(5) NOT NULL ENABLE, 
	"SEED_PLAN_ZONE_CODE" VARCHAR2(3) NOT NULL ENABLE, 
	"ENTRY_USERID" VARCHAR2(30) NOT NULL ENABLE, 
	"ENTRY_TIMESTAMP" DATE NOT NULL ENABLE, 
	"REVISION_COUNT" NUMBER(5,0) NOT NULL ENABLE, 
	"PRIMARY_IND" VARCHAR2(1), 
	 CONSTRAINT "SPZA_PK" PRIMARY KEY ("SEEDLOT_PLAN_ZONE_AUDIT_ID")
  USING INDEX  ENABLE, 
	 CONSTRAINT "SPZA_SAUDC_FK" FOREIGN KEY ("SPAR_AUDIT_CODE")
	  REFERENCES "THE"."SPAR_AUDIT_CODE" ("SPAR_AUDIT_CODE") ENABLE, 
	 CONSTRAINT "SPZA_SPZC_FK" FOREIGN KEY ("SEED_PLAN_ZONE_CODE")
	  REFERENCES "THE"."SEED_PLAN_ZONE_CODE" ("SEED_PLAN_ZONE_CODE") ENABLE
   ) ;

  CREATE TABLE "THE"."SEEDLOT_PLAN_ZONE" 
   (	"SEEDLOT_NUMBER" VARCHAR2(5) NOT NULL ENABLE, 
	"SEED_PLAN_ZONE_CODE" VARCHAR2(3) NOT NULL ENABLE, 
	"ENTRY_USERID" VARCHAR2(30) NOT NULL ENABLE, 
	"ENTRY_TIMESTAMP" DATE NOT NULL ENABLE, 
	"REVISION_COUNT" NUMBER(5,0) NOT NULL ENABLE, 
	"PRIMARY_IND" VARCHAR2(1)
   ) ;
  CREATE UNIQUE INDEX "THE"."SEEDLOT_PLAN_ZONE_PK" ON "THE"."SEEDLOT_PLAN_ZONE" ("SEEDLOT_NUMBER", "SEED_PLAN_ZONE_CODE") 
  ;
ALTER TABLE "THE"."SEEDLOT_PLAN_ZONE" ADD CONSTRAINT "SEEDLOT_PLAN_ZONE_PK" PRIMARY KEY ("SEEDLOT_NUMBER", "SEED_PLAN_ZONE_CODE")
  USING INDEX "THE"."SEEDLOT_PLAN_ZONE_PK"  ENABLE;

  CREATE OR REPLACE EDITIONABLE TRIGGER "THE"."SPR_SL_PLAN_ZONE_AR_IUD_TRG" 
/******************************************************************************
   Trigger: SPR_SL_PLAN_ZONE_AR_IUD_TRG
   Purpose: This trigger audits changes to the SEEDLOT_PLAN_ZONE table
   Revision History
   Person               Date       Comments
   -----------------    ---------  --------------------------------
   R.A.Robb             2005-02-21 Created for PT#25601
******************************************************************************/
AFTER INSERT OR UPDATE OR DELETE ON seedlot_plan_zone
FOR EACH ROW
DECLARE
  v_spar_audit_code    seedlot_plan_zone_audit.spar_audit_code%TYPE;
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
    INSERT INTO seedlot_plan_zone_audit (
            seedlot_plan_zone_audit_id
          , audit_date
          , spar_audit_code
          , seedlot_number
          , seed_plan_zone_code
          , revision_count
          , entry_userid
          , entry_timestamp
          , primary_ind)
         VALUES (
            spza_seq.NEXTVAL
          , SYSDATE
          , v_spar_audit_code
          , :NEW.seedlot_number
          , :NEW.seed_plan_zone_code
          , :NEW.revision_count
          , :NEW.entry_userid
          , :NEW.entry_timestamp
          , :NEW.primary_ind);
  ELSE
    --DELETING: Put the last row into the audit table before deleting
    INSERT INTO seedlot_plan_zone_audit (
            seedlot_plan_zone_audit_id
          , audit_date
          , spar_audit_code
          , seedlot_number
          , seed_plan_zone_code
          , revision_count
          , entry_userid
          , entry_timestamp
          , primary_ind)
         VALUES (
            spza_seq.NEXTVAL
          , SYSDATE
          , v_spar_audit_code
          , :OLD.seedlot_number
          , :OLD.seed_plan_zone_code
          , :OLD.revision_count
          , :OLD.entry_userid
          , :OLD.entry_timestamp
          , :OLD.primary_ind);
  END IF;

END spr_sl_plan_zone_ar_iud_trg;



/
ALTER TRIGGER "THE"."SPR_SL_PLAN_ZONE_AR_IUD_TRG" ENABLE;
