
  CREATE OR REPLACE EDITIONABLE TRIGGER "THE"."TB1$_MAX_CLIENT_NMBR" BEFORE INSERT OR UPDATE ON THE.MAX_CLIENT_NMBR
FOR EACH ROW
BEGIN
:NEW.DUMMY_ACCESS_KEY :=            NVL ( RTRIM ( :NEW.DUMMY_ACCESS_KEY ), ' ' ) ;
:NEW.CLIENT_NUMBER :=            NVL ( RTRIM ( :NEW.CLIENT_NUMBER ), ' ' ) ;
END ;




/
ALTER TRIGGER "THE"."TB1$_MAX_CLIENT_NMBR" ENABLE;

  CREATE OR REPLACE EDITIONABLE TRIGGER "THE"."CLIENT_FOR_CLIENT_AR_IUD_TRG" 
/******************************************************************************
   Trigger: CLIENT_FOR_CLIENT_AR_IUD_TRG
   Purpose: This trigger audits changes to the FOREST_CLIENT table
   Revision History
   Person               Date       Comments
   -----------------    ---------  --------------------------------
   R.A.Robb             2006-12-27 Created
   TMcClelland          2007-08-31 Added client_type_code to trigger insert
******************************************************************************/
AFTER INSERT OR UPDATE OR DELETE
  OF client_number
   , client_name
   , legal_first_name
   , legal_middle_name
   , client_status_code
   , client_type_code
   , birthdate
   , client_id_type_code
   , client_identification
   , registry_company_type_code
   , corp_regn_nmbr
   , client_acronym
   , wcb_firm_number
   , ocg_supplier_nmbr
   , client_comment
  ON forest_client
  FOR EACH ROW
DECLARE
  v_client_audit_code                for_cli_audit.client_audit_code%TYPE;
  v_client_update_action_code        client_update_action_code.client_update_action_code%TYPE;
  v_forest_client_audit_id           for_cli_audit.forest_client_audit_id%TYPE;
BEGIN
  IF INSERTING THEN
    v_client_audit_code := client_constants.c_audit_insert;
  ELSIF UPDATING THEN
    v_client_audit_code := client_constants.c_audit_update;
  ELSE
    v_client_audit_code := client_constants.c_audit_delete;
  END IF;

  IF    INSERTING
     OR UPDATING THEN
    --Put the new row into the audit table
    INSERT INTO for_cli_audit
           (forest_client_audit_id
          , client_audit_code
          , client_number
          , client_name
          , legal_first_name
          , legal_middle_name
          , client_status_code
          , client_type_code
          , birthdate
          , client_id_type_code
          , client_identification
          , registry_company_type_code
          , corp_regn_nmbr
          , client_acronym
          , wcb_firm_number
          , ocg_supplier_nmbr
          , client_comment
          , add_timestamp
          , add_userid
          , add_org_unit
          , update_timestamp
          , update_userid
          , update_org_unit)
    VALUES (forest_client_audit_seq.NEXTVAL
          , v_client_audit_code
          , :NEW.client_number
          , :NEW.client_name
          , :NEW.legal_first_name
          , :NEW.legal_middle_name
          , :NEW.client_status_code
          , :NEW.client_type_code
          , :NEW.birthdate
          , :NEW.client_id_type_code
          , :NEW.client_identification
          , :NEW.registry_company_type_code
          , :NEW.corp_regn_nmbr
          , :NEW.client_acronym
          , :NEW.wcb_firm_number
          , :NEW.ocg_supplier_nmbr
          , :NEW.client_comment
          , :NEW.add_timestamp
          , :NEW.add_userid
          , :NEW.add_org_unit
          , :NEW.update_timestamp
          , :NEW.update_userid
          , :NEW.update_org_unit)
       RETURNING forest_client_audit_id INTO v_forest_client_audit_id;
    --Process update reasons
    IF UPDATING THEN
      --Status Change
      v_client_update_action_code := NULL;
      v_client_update_action_code := client_client_update_reason.check_status
                                    (:OLD.client_status_code
                                     ,:NEW.client_status_code);
      IF v_client_update_action_code IS NOT NULL THEN
        client_client_update_reason.init;
        client_client_update_reason.set_forest_client_audit_id(v_forest_client_audit_id);
        client_client_update_reason.set_client_update_action_code(v_client_update_action_code);
        --get reason from client pkg
        client_client_update_reason.set_client_update_reason_code(client_forest_client.get_ur_reason_status);
        client_client_update_reason.set_client_type_code(:NEW.client_type_code);
        client_client_update_reason.set_add_timestamp(:NEW.update_timestamp);
        client_client_update_reason.set_add_userid(:NEW.update_userid);
        client_client_update_reason.set_update_timestamp(:NEW.update_timestamp);
        client_client_update_reason.set_update_userid(:NEW.update_userid);
        client_client_update_reason.validate;
        IF NOT client_client_update_reason.error_raised THEN
          client_client_update_reason.add;
        END IF;
        IF client_client_update_reason.error_raised THEN
          RAISE_APPLICATION_ERROR(-20400,'Error writing update reason (Status) in audit trigger.');
        END IF;
      END IF;

      --Name Change
      v_client_update_action_code := NULL;
      v_client_update_action_code := client_client_update_reason.check_client_name
                                    (:OLD.client_name
                                    ,:OLD.legal_first_name
                                    ,:OLD.legal_middle_name
                                    ,:NEW.client_name
                                    ,:NEW.legal_first_name
                                    ,:NEW.legal_middle_name);
      IF v_client_update_action_code IS NOT NULL THEN
        client_client_update_reason.init;
        client_client_update_reason.set_forest_client_audit_id(v_forest_client_audit_id);
        client_client_update_reason.set_client_update_action_code(v_client_update_action_code);
        --get reason from client pkg
        client_client_update_reason.set_client_update_reason_code(client_forest_client.get_ur_reason_name);
        client_client_update_reason.set_client_type_code(:NEW.client_type_code);
        client_client_update_reason.set_add_timestamp(:NEW.update_timestamp);
        client_client_update_reason.set_add_userid(:NEW.update_userid);
        client_client_update_reason.set_update_timestamp(:NEW.update_timestamp);
        client_client_update_reason.set_update_userid(:NEW.update_userid);
        client_client_update_reason.validate;
        IF NOT client_client_update_reason.error_raised THEN
          client_client_update_reason.add;
        END IF;
        IF client_client_update_reason.error_raised THEN
          RAISE_APPLICATION_ERROR(-20400,'Error writing update reason (Name) in audit trigger.');
        END IF;
      END IF;

      --ID Change
      v_client_update_action_code := NULL;
      v_client_update_action_code := client_client_update_reason.check_id
                                    (:OLD.client_identification
                                    ,:OLD.client_id_type_code
                                    ,:NEW.client_identification
                                    ,:NEW.client_id_type_code);
      IF v_client_update_action_code IS NOT NULL THEN
        client_client_update_reason.init;
        client_client_update_reason.set_forest_client_audit_id(v_forest_client_audit_id);
        client_client_update_reason.set_client_update_action_code(v_client_update_action_code);
        --get reason from client pkg
        client_client_update_reason.set_client_update_reason_code(client_forest_client.get_ur_reason_id);
        client_client_update_reason.set_client_type_code(:NEW.client_type_code);
        client_client_update_reason.set_add_timestamp(:NEW.update_timestamp);
        client_client_update_reason.set_add_userid(:NEW.update_userid);
        client_client_update_reason.set_update_timestamp(:NEW.update_timestamp);
        client_client_update_reason.set_update_userid(:NEW.update_userid);
        client_client_update_reason.validate;
        IF NOT client_client_update_reason.error_raised THEN
          client_client_update_reason.add;
        END IF;
        IF client_client_update_reason.error_raised THEN
          RAISE_APPLICATION_ERROR(-20400,'Error writing update reason (Id) in audit trigger.');
        END IF;
      END IF;

    END IF;
  ELSE
    --DELETING: Put the last row into the audit table before deleting
    --          replacing update userid/timestamp/org
    -->check PK to make sure we are deleting the record in progress
    IF  client_forest_client.get_client_number = :OLD.client_number
    -->check that userid and timestamp are available
    AND client_forest_client.get_update_timestamp IS NOT NULL
    AND client_forest_client.get_update_userid IS NOT NULL
    AND client_forest_client.get_update_org_unit IS NOT NULL THEN
      INSERT INTO for_cli_audit
             (forest_client_audit_id
            , client_audit_code
            , client_number
            , client_name
            , legal_first_name
            , legal_middle_name
            , client_status_code
            , client_type_code
            , birthdate
            , client_id_type_code
            , client_identification
            , registry_company_type_code
            , corp_regn_nmbr
            , client_acronym
            , wcb_firm_number
            , ocg_supplier_nmbr
            , client_comment
            , add_timestamp
            , add_userid
            , add_org_unit
            , update_timestamp
            , update_userid
            , update_org_unit)
      VALUES (forest_client_audit_seq.NEXTVAL
            , v_client_audit_code
            , :OLD.client_number
            , :OLD.client_name
            , :OLD.legal_first_name
            , :OLD.legal_middle_name
            , :OLD.client_status_code
            , :OLD.client_type_code
            , :OLD.birthdate
            , :OLD.client_id_type_code
            , :OLD.client_identification
            , :OLD.registry_company_type_code
            , :OLD.corp_regn_nmbr
            , :OLD.client_acronym
            , :OLD.wcb_firm_number
            , :OLD.ocg_supplier_nmbr
            , :OLD.client_comment
            , :OLD.add_timestamp
            , :OLD.add_userid
            , :OLD.add_org_unit
              , client_forest_client.get_update_timestamp
              , client_forest_client.get_update_userid
              , client_forest_client.get_update_org_unit);
    ELSE
      RAISE_APPLICATION_ERROR(-20500,'Data consistency error in auditing deletion of FOREST_CLIENT');
    END IF;
  END IF;
END client_for_client_ar_iud_trg;




/
ALTER TRIGGER "THE"."CLIENT_FOR_CLIENT_AR_IUD_TRG" ENABLE;

  CREATE OR REPLACE EDITIONABLE TRIGGER "THE"."CLIENT_CLIENT_LOCN_AR_IUD_TRG" 
/******************************************************************************
   Trigger: CLIENT_CLIENT_LOCN_AR_IUD_TRG
   Purpose: This trigger audits changes to the CLIENT_LOCATION table
   Revision History
   Person               Date       Comments
   -----------------    ---------  --------------------------------
   R.A.Robb             2006-12-27 Created
   TMcClelland          2007-08-31 Added client_type_code to trigger insert
******************************************************************************/
AFTER INSERT OR UPDATE OR DELETE
  OF client_number
   , client_locn_code
   , client_locn_name
   , hdbs_company_code
   , address_1
   , address_2
   , address_3
   , city
   , province
   , postal_code
   , country
   , business_phone
   , home_phone
   , cell_phone
   , fax_number
   , email_address
   , locn_expired_ind
   , returned_mail_date
   , trust_location_ind
   , cli_locn_comment
  ON client_location
  FOR EACH ROW
DECLARE
  v_client_audit_code                cli_locn_audit.client_audit_code%TYPE;
  v_client_update_action_code        client_update_action_code.client_update_action_code%TYPE;
  v_client_update_reason_code        client_update_reason_code.client_update_reason_code%TYPE;
BEGIN
  IF INSERTING THEN
    v_client_audit_code := client_constants.c_audit_insert;
  ELSIF UPDATING THEN
    v_client_audit_code := client_constants.c_audit_update;
  ELSE
    v_client_audit_code := client_constants.c_audit_delete;
  END IF;

  IF    INSERTING
     OR UPDATING THEN

    --Process update reasons
    IF UPDATING THEN
      --Address Change
      v_client_update_action_code := NULL;
      v_client_update_action_code := client_client_update_reason.check_address
                                    (:OLD.address_1
                                    ,:OLD.address_2
                                    ,:OLD.address_3
                                    ,:OLD.city
                                    ,:OLD.province
                                    ,:OLD.postal_code
                                    ,:OLD.country
                                    ,:NEW.address_1
                                    ,:NEW.address_2
                                    ,:NEW.address_3
                                    ,:NEW.city
                                    ,:NEW.province
                                    ,:NEW.postal_code
                                    ,:NEW.country);
      IF v_client_update_action_code IS NOT NULL THEN
        --get reason from client locn pkg
        v_client_update_reason_code := client_client_location.get_ur_reason_addr;
      END IF;
    END IF;

    --Put the new row into the audit table
    INSERT INTO cli_locn_audit
           (client_location_audit_id
          , client_audit_code
          , client_number
          , client_locn_code
          , client_locn_name
          , hdbs_company_code
          , address_1
          , address_2
          , address_3
          , city
          , province
          , postal_code
          , country
          , business_phone
          , home_phone
          , cell_phone
          , fax_number
          , email_address
          , locn_expired_ind
          , returned_mail_date
          , trust_location_ind
          , cli_locn_comment
          , client_update_action_code
          , client_update_reason_code
          , client_type_code
          , update_timestamp
          , update_userid
          , update_org_unit
          , add_timestamp
          , add_userid
          , add_org_unit)
    SELECT client_location_audit_seq.nextval
          , v_client_audit_code
          , :NEW.client_number
          , :NEW.client_locn_code
          , :NEW.client_locn_name
          , :NEW.hdbs_company_code
          , :NEW.address_1
          , :NEW.address_2
          , :NEW.address_3
          , :NEW.city
          , :NEW.province
          , :NEW.postal_code
          , :NEW.country
          , :NEW.business_phone
          , :NEW.home_phone
          , :NEW.cell_phone
          , :NEW.fax_number
          , :NEW.email_address
          , :NEW.locn_expired_ind
          , :NEW.returned_mail_date
          , :NEW.trust_location_ind
          , :NEW.cli_locn_comment
          , v_client_update_action_code
          , v_client_update_reason_code
          , client_type_code
          , :NEW.update_timestamp
          , :NEW.update_userid
          , :NEW.update_org_unit
          , :NEW.add_timestamp
          , :NEW.add_userid
          , :NEW.add_org_unit
    FROM forest_client
    WHERE client_number = :NEW.client_number;

  ELSE
    --DELETING: Put the last row into the audit table before deleting
    --          replacing update userid/timestamp/org
    -->check PK to make sure we are deleting the record in progress
    IF  client_client_location.get_client_number = :OLD.client_number
    AND client_client_location.get_client_locn_code = :OLD.client_locn_code
    -->check that userid and timestamp are available
    AND client_client_location.get_update_timestamp IS NOT NULL
    AND client_client_location.get_update_userid IS NOT NULL
    AND client_client_location.get_update_org_unit IS NOT NULL THEN
       INSERT INTO cli_locn_audit
             (client_location_audit_id
            , client_audit_code
            , client_number
            , client_locn_code
            , client_locn_name
            , hdbs_company_code
            , address_1
            , address_2
            , address_3
            , city
            , province
            , postal_code
            , country
            , business_phone
            , home_phone
            , cell_phone
            , fax_number
            , email_address
            , locn_expired_ind
            , returned_mail_date
            , trust_location_ind
            , cli_locn_comment
            , update_timestamp
            , update_userid
            , update_org_unit
            , add_timestamp
            , add_userid
            , add_org_unit)
      VALUES (client_location_audit_seq.nextval
            , v_client_audit_code
            , :OLD.client_number
            , :OLD.client_locn_code
            , :OLD.client_locn_name
            , :OLD.hdbs_company_code
            , :OLD.address_1
            , :OLD.address_2
            , :OLD.address_3
            , :OLD.city
            , :OLD.province
            , :OLD.postal_code
            , :OLD.country
            , :OLD.business_phone
            , :OLD.home_phone
            , :OLD.cell_phone
            , :OLD.fax_number
            , :OLD.email_address
            , :OLD.locn_expired_ind
            , :OLD.returned_mail_date
            , :OLD.trust_location_ind
            , :OLD.cli_locn_comment
            , client_client_location.get_update_timestamp
            , client_client_location.get_update_userid
            , client_client_location.get_update_org_unit
            , :OLD.add_timestamp
            , :OLD.add_userid
            , :OLD.add_org_unit);
    ELSE
      RAISE_APPLICATION_ERROR(-20500,'Data consistency error in auditing deletion of CLIENT_LOCATION');
    END IF;
  END IF;
END client_client_locn_ar_iud_trg;




/
ALTER TRIGGER "THE"."CLIENT_CLIENT_LOCN_AR_IUD_TRG" ENABLE;

  CREATE OR REPLACE EDITIONABLE TRIGGER "THE"."SPR_SEEDLOT_AR_IUD_TRG" 
/******************************************************************************
   Trigger: SPR_SEEDLOT_AR_IUD_TRG
   Purpose: This trigger audits changes to the SEEDLOT table

   Revision History
   Person               Date       Comments
   -----------------    ---------  --------------------------------
   R.A.Robb             2005-01-20 Created for PT#25601
   R.A.Robb             2005-03-14 PT#26063 - added COLLECTION_LAT_SEC, COLLECTION_LONG_SEC,
                                   LATITUDE_SECONDS, LONGITUDE_SECONDS
   R.A.Robb             2006-01-12 PT#28861 - added COANCESTRY
   E.Wong               2008-07-16 PT#41508-added BEC_VERSION_ID.
******************************************************************************/
AFTER INSERT OR UPDATE OR DELETE ON seedlot
FOR EACH ROW
DECLARE
  v_spar_audit_code    seedlot_audit.spar_audit_code%TYPE;
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
    INSERT INTO seedlot_audit (
            seedlot_audit_id
          , audit_date
          , spar_audit_code
          , seedlot_number
          , seedlot_status_code
          , vegetation_code
          , genetic_class_code
          , collection_source_code
          , superior_prvnc_ind
          , org_unit_no
          , registered_seed_ind
          , to_be_registrd_ind
          , registered_date
          , fs721a_signed_ind
          , nad_datum_code
          , utm_zone
          , utm_easting
          , utm_northing
          , longitude_degrees
          , longitude_minutes
          , longitude_seconds
          , longitude_deg_min
          , longitude_min_min
          , longitude_deg_max
          , longitude_min_max
          , latitude_degrees
          , latitude_minutes
          , latitude_seconds
          , latitude_deg_min
          , latitude_min_min
          , latitude_deg_max
          , latitude_min_max
          , seed_coast_area_code
          , elevation
          , elevation_min
          , elevation_max
          , orchard_id
          , collection_locn_desc
          , collection_cli_number
          , collection_cli_locn_cd
          , collection_start_date
          , collection_end_date
          , cone_collection_method_code
          , no_of_containers
          , clctn_volume
          , vol_per_container
          , nmbr_trees_from_code
          , effective_pop_size
          , original_seed_qty
          , interm_strg_st_date
          , interm_strg_end_date
          , interm_facility_code
          , extraction_st_date
          , extraction_end_date
          , extraction_volume
          , extrct_cli_number
          , extrct_cli_locn_cd
          , stored_cli_number
          , stored_cli_locn_cd
          , lngterm_strg_st_date
          , historical_tsr_date
          , collection_lat_deg
          , collection_lat_min
          , collection_lat_sec
          , collection_latitude_code
          , collection_long_deg
          , collection_long_min
          , collection_long_sec
          , collection_longitude_code
          , collection_elevation
          , collection_elevation_min
          , collection_elevation_max
          , entry_timestamp
          , entry_userid
          , update_timestamp
          , update_userid
          , approved_timestamp
          , approved_userid
          , revision_count
          , interm_strg_locn
          , interm_strg_cmt
          , ownership_comment
          , cone_seed_desc
          , extraction_comment
          , seedlot_comment
          , bgc_zone_code
          , bgc_subzone_code
          , variant
          , bec_version_id
          , seed_plan_zone_code
          , applicant_client_locn
          , applicant_client_number
          , applicant_email_address
          , bc_source_ind
          , biotech_processes_ind
          , collection_area_radius
          , collection_bgc_ind
          , collection_seed_plan_zone_ind
          , collection_standard_met_ind
          , cone_collection_method2_code
          , contaminant_pollen_bv
          , controlled_cross_ind
          , declared_userid
          , female_gametic_mthd_code
          , latitude_sec_max
          , latitude_sec_min
          , longitude_sec_max
          , longitude_sec_min
          , male_gametic_mthd_code
          , orchard_comment
          , orchard_contamination_pct
          , pollen_contamination_ind
          , pollen_contamination_mthd_code
          , pollen_contamination_pct
          , provenance_id
          , secondary_orchard_id
          , seed_plan_unit_id
          , seed_store_client_locn
          , seed_store_client_number
          , seedlot_source_code
          , smp_mean_bv_growth
          , smp_parents_outside
          , smp_success_pct
          , temporary_storage_end_date
          , temporary_storage_start_date
          , total_parent_trees
          , interm_strg_client_number
          , interm_strg_client_locn
          , declared_timestamp
          , coancestry
          , price_per_kg
          , price_comment
        ) VALUES (
            saud_seq.NEXTVAL
          , SYSDATE
          , v_spar_audit_code
          , :NEW.seedlot_number
          , :NEW.seedlot_status_code
          , :NEW.vegetation_code
          , :NEW.genetic_class_code
          , :NEW.collection_source_code
          , :NEW.superior_prvnc_ind
          , :NEW.org_unit_no
          , :NEW.registered_seed_ind
          , :NEW.to_be_registrd_ind
          , :NEW.registered_date
          , :NEW.fs721a_signed_ind
          , :NEW.nad_datum_code
          , :NEW.utm_zone
          , :NEW.utm_easting
          , :NEW.utm_northing
          , :NEW.longitude_degrees
          , :NEW.longitude_minutes
          , :NEW.longitude_seconds
          , :NEW.longitude_deg_min
          , :NEW.longitude_min_min
          , :NEW.longitude_deg_max
          , :NEW.longitude_min_max
          , :NEW.latitude_degrees
          , :NEW.latitude_minutes
          , :NEW.latitude_seconds
          , :NEW.latitude_deg_min
          , :NEW.latitude_min_min
          , :NEW.latitude_deg_max
          , :NEW.latitude_min_max
          , :NEW.seed_coast_area_code
          , :NEW.elevation
          , :NEW.elevation_min
          , :NEW.elevation_max
          , :NEW.orchard_id
          , :NEW.collection_locn_desc
          , :NEW.collection_cli_number
          , :NEW.collection_cli_locn_cd
          , :NEW.collection_start_date
          , :NEW.collection_end_date
          , :NEW.cone_collection_method_code
          , :NEW.no_of_containers
          , :NEW.clctn_volume
          , :NEW.vol_per_container
          , :NEW.nmbr_trees_from_code
          , :NEW.effective_pop_size
          , :NEW.original_seed_qty
          , :NEW.interm_strg_st_date
          , :NEW.interm_strg_end_date
          , :NEW.interm_facility_code
          , :NEW.extraction_st_date
          , :NEW.extraction_end_date
          , :NEW.extraction_volume
          , :NEW.extrct_cli_number
          , :NEW.extrct_cli_locn_cd
          , :NEW.stored_cli_number
          , :NEW.stored_cli_locn_cd
          , :NEW.lngterm_strg_st_date
          , :NEW.historical_tsr_date
          , :NEW.collection_lat_deg
          , :NEW.collection_lat_min
          , :NEW.collection_lat_sec
          , :NEW.collection_latitude_code
          , :NEW.collection_long_deg
          , :NEW.collection_long_min
          , :NEW.collection_long_sec
          , :NEW.collection_longitude_code
          , :NEW.collection_elevation
          , :NEW.collection_elevation_min
          , :NEW.collection_elevation_max
          , :NEW.entry_timestamp
          , :NEW.entry_userid
          , :NEW.update_timestamp
          , :NEW.update_userid
          , :NEW.approved_timestamp
          , :NEW.approved_userid
          , :NEW.revision_count
          , :NEW.interm_strg_locn
          , :NEW.interm_strg_cmt
          , :NEW.ownership_comment
          , :NEW.cone_seed_desc
          , :NEW.extraction_comment
          , :NEW.seedlot_comment
          , :NEW.bgc_zone_code
          , :NEW.bgc_subzone_code
          , :NEW.variant
          , :NEW.bec_version_id
          , :NEW.seed_plan_zone_code
          , :NEW.applicant_client_locn
          , :NEW.applicant_client_number
          , :NEW.applicant_email_address
          , :NEW.bc_source_ind
          , :NEW.biotech_processes_ind
          , :NEW.collection_area_radius
          , :NEW.collection_bgc_ind
          , :NEW.collection_seed_plan_zone_ind
          , :NEW.collection_standard_met_ind
          , :NEW.cone_collection_method2_code
          , :NEW.contaminant_pollen_bv
          , :NEW.controlled_cross_ind
          , :NEW.declared_userid
          , :NEW.female_gametic_mthd_code
          , :NEW.latitude_sec_max
          , :NEW.latitude_sec_min
          , :NEW.longitude_sec_max
          , :NEW.longitude_sec_min
          , :NEW.male_gametic_mthd_code
          , :NEW.orchard_comment
          , :NEW.orchard_contamination_pct
          , :NEW.pollen_contamination_ind
          , :NEW.pollen_contamination_mthd_code
          , :NEW.pollen_contamination_pct
          , :NEW.provenance_id
          , :NEW.secondary_orchard_id
          , :NEW.seed_plan_unit_id
          , :NEW.seed_store_client_locn
          , :NEW.seed_store_client_number
          , :NEW.seedlot_source_code
          , :NEW.smp_mean_bv_growth
          , :NEW.smp_parents_outside
          , :NEW.smp_success_pct
          , :NEW.temporary_storage_end_date
          , :NEW.temporary_storage_start_date
          , :NEW.total_parent_trees
          , :NEW.interm_strg_client_number
          , :NEW.interm_strg_client_locn
          , :NEW.declared_timestamp
          , :NEW.coancestry
          , :NEW.PRICE_PER_KG
          , :NEW.PRICE_COMMENT
       );
  ELSE
    --DELETING: Put the last row into the audit table before deleting
    INSERT INTO seedlot_audit (
            seedlot_audit_id
          , audit_date
          , spar_audit_code
          , seedlot_number
          , seedlot_status_code
          , vegetation_code
          , genetic_class_code
          , collection_source_code
          , superior_prvnc_ind
          , org_unit_no
          , registered_seed_ind
          , to_be_registrd_ind
          , registered_date
          , fs721a_signed_ind
          , nad_datum_code
          , utm_zone
          , utm_easting
          , utm_northing
          , longitude_degrees
          , longitude_minutes
          , longitude_seconds
          , longitude_deg_min
          , longitude_min_min
          , longitude_deg_max
          , longitude_min_max
          , latitude_degrees
          , latitude_minutes
          , latitude_seconds
          , latitude_deg_min
          , latitude_min_min
          , latitude_deg_max
          , latitude_min_max
          , seed_coast_area_code
          , elevation
          , elevation_min
          , elevation_max
          , orchard_id
          , collection_locn_desc
          , collection_cli_number
          , collection_cli_locn_cd
          , collection_start_date
          , collection_end_date
          , cone_collection_method_code
          , no_of_containers
          , clctn_volume
          , vol_per_container
          , nmbr_trees_from_code
          , effective_pop_size
          , original_seed_qty
          , interm_strg_st_date
          , interm_strg_end_date
          , interm_facility_code
          , extraction_st_date
          , extraction_end_date
          , extraction_volume
          , extrct_cli_number
          , extrct_cli_locn_cd
          , stored_cli_number
          , stored_cli_locn_cd
          , lngterm_strg_st_date
          , historical_tsr_date
          , collection_lat_deg
          , collection_lat_min
          , collection_lat_sec
          , collection_latitude_code
          , collection_long_deg
          , collection_long_min
          , collection_long_sec
          , collection_longitude_code
          , collection_elevation
          , collection_elevation_min
          , collection_elevation_max
          , entry_timestamp
          , entry_userid
          , update_timestamp
          , update_userid
          , approved_timestamp
          , approved_userid
          , revision_count
          , interm_strg_locn
          , interm_strg_cmt
          , ownership_comment
          , cone_seed_desc
          , extraction_comment
          , seedlot_comment
          , bgc_zone_code
          , bgc_subzone_code
          , variant
          , bec_version_id
          , seed_plan_zone_code
          , applicant_client_locn
          , applicant_client_number
          , applicant_email_address
          , bc_source_ind
          , biotech_processes_ind
          , collection_area_radius
          , collection_bgc_ind
          , collection_seed_plan_zone_ind
          , collection_standard_met_ind
          , cone_collection_method2_code
          , contaminant_pollen_bv
          , controlled_cross_ind
          , declared_userid
          , female_gametic_mthd_code
          , latitude_sec_max
          , latitude_sec_min
          , longitude_sec_max
          , longitude_sec_min
          , male_gametic_mthd_code
          , orchard_comment
          , orchard_contamination_pct
          , pollen_contamination_ind
          , pollen_contamination_mthd_code
          , pollen_contamination_pct
          , provenance_id
          , secondary_orchard_id
          , seed_plan_unit_id
          , seed_store_client_locn
          , seed_store_client_number
          , seedlot_source_code
          , smp_mean_bv_growth
          , smp_parents_outside
          , smp_success_pct
          , temporary_storage_end_date
          , temporary_storage_start_date
          , total_parent_trees
          , interm_strg_client_number
          , interm_strg_client_locn
          , declared_timestamp
          , coancestry
          , price_per_kg
          , price_comment
        ) VALUES (
            saud_seq.NEXTVAL
          , SYSDATE
          , v_spar_audit_code
          , :OLD.seedlot_number
          , :OLD.seedlot_status_code
          , :OLD.vegetation_code
          , :OLD.genetic_class_code
          , :OLD.collection_source_code
          , :OLD.superior_prvnc_ind
          , :OLD.org_unit_no
          , :OLD.registered_seed_ind
          , :OLD.to_be_registrd_ind
          , :OLD.registered_date
          , :OLD.fs721a_signed_ind
          , :OLD.nad_datum_code
          , :OLD.utm_zone
          , :OLD.utm_easting
          , :OLD.utm_northing
          , :OLD.longitude_degrees
          , :OLD.longitude_minutes
          , :OLD.longitude_seconds
          , :OLD.longitude_deg_min
          , :OLD.longitude_min_min
          , :OLD.longitude_deg_max
          , :OLD.longitude_min_max
          , :OLD.latitude_degrees
          , :OLD.latitude_minutes
          , :OLD.latitude_seconds
          , :OLD.latitude_deg_min
          , :OLD.latitude_min_min
          , :OLD.latitude_deg_max
          , :OLD.latitude_min_max
          , :OLD.seed_coast_area_code
          , :OLD.elevation
          , :OLD.elevation_min
          , :OLD.elevation_max
          , :OLD.orchard_id
          , :OLD.collection_locn_desc
          , :OLD.collection_cli_number
          , :OLD.collection_cli_locn_cd
          , :OLD.collection_start_date
          , :OLD.collection_end_date
          , :OLD.cone_collection_method_code
          , :OLD.no_of_containers
          , :OLD.clctn_volume
          , :OLD.vol_per_container
          , :OLD.nmbr_trees_from_code
          , :OLD.effective_pop_size
          , :OLD.original_seed_qty
          , :OLD.interm_strg_st_date
          , :OLD.interm_strg_end_date
          , :OLD.interm_facility_code
          , :OLD.extraction_st_date
          , :OLD.extraction_end_date
          , :OLD.extraction_volume
          , :OLD.extrct_cli_number
          , :OLD.extrct_cli_locn_cd
          , :OLD.stored_cli_number
          , :OLD.stored_cli_locn_cd
          , :OLD.lngterm_strg_st_date
          , :OLD.historical_tsr_date
          , :OLD.collection_lat_deg
          , :OLD.collection_lat_min
          , :OLD.collection_lat_sec
          , :OLD.collection_latitude_code
          , :OLD.collection_long_deg
          , :OLD.collection_long_min
          , :OLD.collection_long_sec
          , :OLD.collection_longitude_code
          , :OLD.collection_elevation
          , :OLD.collection_elevation_min
          , :OLD.collection_elevation_max
          , :OLD.entry_timestamp
          , :OLD.entry_userid
          , :OLD.update_timestamp
          , :OLD.update_userid
          , :OLD.approved_timestamp
          , :OLD.approved_userid
          , :OLD.revision_count
          , :OLD.interm_strg_locn
          , :OLD.interm_strg_cmt
          , :OLD.ownership_comment
          , :OLD.cone_seed_desc
          , :OLD.extraction_comment
          , :OLD.seedlot_comment
          , :OLD.bgc_zone_code
          , :OLD.bgc_subzone_code
          , :OLD.variant
          , :OLD.bec_version_id
          , :OLD.seed_plan_zone_code
          , :OLD.applicant_client_locn
          , :OLD.applicant_client_number
          , :OLD.applicant_email_address
          , :OLD.bc_source_ind
          , :OLD.biotech_processes_ind
          , :OLD.collection_area_radius
          , :OLD.collection_bgc_ind
          , :OLD.collection_seed_plan_zone_ind
          , :OLD.collection_standard_met_ind
          , :OLD.cone_collection_method2_code
          , :OLD.contaminant_pollen_bv
          , :OLD.controlled_cross_ind
          , :OLD.declared_userid
          , :OLD.female_gametic_mthd_code
          , :OLD.latitude_sec_max
          , :OLD.latitude_sec_min
          , :OLD.longitude_sec_max
          , :OLD.longitude_sec_min
          , :OLD.male_gametic_mthd_code
          , :OLD.orchard_comment
          , :OLD.orchard_contamination_pct
          , :OLD.pollen_contamination_ind
          , :OLD.pollen_contamination_mthd_code
          , :OLD.pollen_contamination_pct
          , :OLD.provenance_id
          , :OLD.secondary_orchard_id
          , :OLD.seed_plan_unit_id
          , :OLD.seed_store_client_locn
          , :OLD.seed_store_client_number
          , :OLD.seedlot_source_code
          , :OLD.smp_mean_bv_growth
          , :OLD.smp_parents_outside
          , :OLD.smp_success_pct
          , :OLD.temporary_storage_end_date
          , :OLD.temporary_storage_start_date
          , :OLD.total_parent_trees
          , :OLD.interm_strg_client_number
          , :OLD.interm_strg_client_locn
          , :OLD.declared_timestamp
          , :OLD.coancestry
          , :OLD.PRICE_PER_KG
          , :OLD.PRICE_COMMENT
      );
  END IF;

END spr_seedlot_ar_iud_trg;



/
ALTER TRIGGER "THE"."SPR_SEEDLOT_AR_IUD_TRG" ENABLE;
