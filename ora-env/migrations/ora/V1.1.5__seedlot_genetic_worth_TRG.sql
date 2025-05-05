
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
