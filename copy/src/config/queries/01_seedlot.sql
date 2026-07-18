--------------------------------------------------------------------------------
-- spar.seedlot  <-  THE.seedlot
--------------------------------------------------------------------------------
-- One row per seedlot. This is the reverse of the sync tool's
-- config/SQL/SPAR/POSTGRES_SEEDLOT_EXTRACT.sql, so the transformations mirror
-- (and invert) that query:
--   * Y/N char flags in Oracle  -> Postgres boolean (Y=true, N=false)
--   * userids: Oracle stores "Provider@User", Postgres stores "Provider\User"
--   * timestamps: Oracle stores Pacific local time; Postgres stores UTC, so
--     values are converted America/Los_Angeles -> UTC.
--   * orchard / cone-collection-method / seed-plan-zone data lives in separate
--     Postgres child tables and is handled by the other query files.
-- Every column is aliased to its exact Postgres (spar.seedlot) column name.
--------------------------------------------------------------------------------
SELECT
     s.applicant_client_number                                       AS applicant_client_number
   , s.applicant_email_address                                       AS applicant_email_address
   , s.applicant_client_locn                                         AS applicant_locn_code
   , CAST(FROM_TZ(CAST(s.approved_timestamp AS TIMESTAMP), 'America/Los_Angeles') AT TIME ZONE 'UTC' AS TIMESTAMP) AS approved_timestamp
   , REPLACE(s.approved_userid, '@', '\')                            AS approved_userid
   , s.orchard_comment                                               AS area_of_use_comment
   , CASE WHEN s.bc_source_ind = 'Y' THEN 'true' ELSE 'false' END    AS bc_source_ind
   , s.bec_version_id                                                AS bec_version_id
   , s.bgc_subzone_code                                              AS bgc_subzone_code
   , s.bgc_zone_code                                                 AS bgc_zone_code
   , CASE WHEN s.biotech_processes_ind = 'Y' THEN 'true'
          WHEN s.biotech_processes_ind = 'N' THEN 'false'
          ELSE NULL END                                              AS biotech_processes_ind
   , s.clctn_volume                                                  AS clctn_volume
   , s.collection_cli_number                                         AS collection_client_number
   , s.collection_elevation                                          AS collection_elevation
   , s.collection_elevation_max                                      AS collection_elevation_max
   , s.collection_elevation_min                                      AS collection_elevation_min
   , CAST(s.collection_end_date AS DATE)                             AS collection_end_date
   , s.collection_latitude_code                                      AS collection_latitude_code
   , s.collection_lat_deg                                            AS collection_latitude_deg
   , s.collection_lat_min                                            AS collection_latitude_min
   , s.collection_lat_sec                                            AS collection_latitude_sec
   , s.collection_cli_locn_cd                                        AS collection_locn_code
   , s.collection_longitude_code                                     AS collection_longitude_code
   , s.collection_long_deg                                           AS collection_longitude_deg
   , s.collection_long_min                                           AS collection_longitude_min
   , s.collection_long_sec                                           AS collection_longitude_sec
   , CAST(s.collection_start_date AS DATE)                           AS collection_start_date
   , s.contaminant_pollen_bv                                         AS contaminant_pollen_bv
   , CASE WHEN s.controlled_cross_ind = 'Y' THEN 'true'
          WHEN s.controlled_cross_ind = 'N' THEN 'false'
          ELSE NULL END                                              AS controlled_cross_ind
   , CAST(FROM_TZ(CAST(s.declared_timestamp AS TIMESTAMP), 'America/Los_Angeles') AT TIME ZONE 'UTC' AS TIMESTAMP) AS declared_timestamp
   , REPLACE(s.declared_userid, '@', '\')                            AS declared_userid
   , s.effective_pop_size                                            AS effective_pop_size
   , s.elevation                                                     AS elevation
   , s.elevation_max                                                 AS elevation_max
   , s.elevation_min                                                 AS elevation_min
   , CAST(FROM_TZ(CAST(s.entry_timestamp AS TIMESTAMP), 'America/Los_Angeles') AT TIME ZONE 'UTC' AS TIMESTAMP) AS entry_timestamp
   , REPLACE(s.entry_userid, '@', '\')                               AS entry_userid
   , CAST(s.extraction_end_date AS DATE)                             AS extraction_end_date
   , CAST(s.extraction_st_date AS DATE)                              AS extraction_st_date
   , s.extrct_cli_number                                             AS extractory_client_number
   , s.extrct_cli_locn_cd                                            AS extractory_locn_code
   , s.female_gametic_mthd_code                                      AS female_gametic_mthd_code
   , s.genetic_class_code                                            AS genetic_class_code
   , s.interm_facility_code                                          AS interm_facility_code
   , s.interm_strg_client_number                                     AS interm_strg_client_number
   , CAST(s.interm_strg_end_date AS DATE)                            AS interm_strg_end_date
   , s.interm_strg_locn                                              AS interm_strg_locn
   , s.interm_strg_client_locn                                       AS interm_strg_locn_code
   , CAST(s.interm_strg_st_date AS DATE)                             AS interm_strg_st_date
   , s.latitude_deg_max                                              AS latitude_deg_max
   , s.latitude_deg_min                                              AS latitude_deg_min
   , s.latitude_degrees                                              AS latitude_degrees
   , s.latitude_min_max                                              AS latitude_min_max
   , s.latitude_min_min                                              AS latitude_min_min
   , s.latitude_minutes                                              AS latitude_minutes
   , s.latitude_sec_max                                              AS latitude_sec_max
   , s.latitude_sec_min                                              AS latitude_sec_min
   , s.latitude_seconds                                              AS latitude_seconds
   , s.longitude_deg_max                                             AS longitude_deg_max
   , s.longitude_deg_min                                             AS longitude_deg_min
   , s.longitude_degrees                                             AS longitude_degrees
   , s.longitude_min_max                                             AS longitude_min_max
   , s.longitude_min_min                                             AS longitude_min_min
   , s.longitude_minutes                                             AS longitude_minutes
   , s.longitude_sec_max                                             AS longitude_sec_max
   , s.longitude_sec_min                                             AS longitude_sec_min
   , s.longitude_seconds                                             AS longitude_seconds
   , s.male_gametic_mthd_code                                        AS male_gametic_mthd_code
   , s.no_of_containers                                              AS no_of_containers
   -- No Oracle source column; Postgres-only, left null.
   , CAST(NULL AS NUMBER)                                            AS non_orchard_pollen_contam_pct
   , CASE WHEN s.pollen_contamination_ind = 'Y' THEN 'true'
          WHEN s.pollen_contamination_ind = 'N' THEN 'false'
          ELSE NULL END                                              AS pollen_contamination_ind
   , s.pollen_contamination_mthd_code                                AS pollen_contamination_mthd_code
   , s.pollen_contamination_pct                                      AS pollen_contamination_pct
   , s.revision_count                                                AS revision_count
   , s.seed_plan_unit_id                                             AS seed_plan_unit_id
   , s.seedlot_comment                                               AS seedlot_comment
   , s.seedlot_number                                                AS seedlot_number
   , s.seedlot_source_code                                           AS seedlot_source_code
   , s.seedlot_status_code                                           AS seedlot_status_code
   , s.smp_mean_bv_growth                                            AS smp_mean_bv_growth
   , s.smp_parents_outside                                           AS smp_parents_outside
   , s.smp_success_pct                                               AS smp_success_pct
   , s.seed_store_client_number                                      AS temporary_strg_client_number
   , CAST(s.temporary_storage_end_date AS DATE)                      AS temporary_strg_end_date
   , s.seed_store_client_locn                                        AS temporary_strg_locn_code
   , CAST(s.temporary_storage_start_date AS DATE)                    AS temporary_strg_start_date
   , CASE WHEN s.to_be_registrd_ind = 'Y' THEN 'true' ELSE 'false' END AS to_be_registrd_ind
   , s.total_parent_trees                                            AS total_parent_trees
   , CAST(FROM_TZ(CAST(s.update_timestamp AS TIMESTAMP), 'America/Los_Angeles') AT TIME ZONE 'UTC' AS TIMESTAMP) AS update_timestamp
   , REPLACE(s.update_userid, '@', '\')                              AS update_userid
   , s.variant                                                       AS variant
   , s.vegetation_code                                               AS vegetation_code
   , s.vol_per_container                                             AS vol_per_container
FROM the.seedlot s
WHERE s.seedlot_number = :seedlot_number
