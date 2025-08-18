
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
