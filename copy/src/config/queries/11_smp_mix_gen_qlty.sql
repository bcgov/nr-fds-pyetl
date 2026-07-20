--------------------------------------------------------------------------------
-- spar.smp_mix_gen_qlty  <-  THE.smp_mix_gen_qlty
--------------------------------------------------------------------------------
-- Target columns confirmed against bcgov/nr-spar common/init_db/init.sql.
--   * estimated_ind is boolean NOT NULL in Postgres, so the Oracle Y/N char
--     value is converted.
--   * entry/update audit columns are NOT NULL in Postgres.
--------------------------------------------------------------------------------
SELECT
     s.seedlot_number                                   AS seedlot_number
   , s.parent_tree_id                                   AS parent_tree_id
   , s.genetic_type_code                                AS genetic_type_code
   , s.genetic_worth_code                               AS genetic_worth_code
   , s.genetic_quality_value                            AS genetic_quality_value
   , CASE WHEN s.estimated_ind = 'Y' THEN 'true'
          WHEN s.estimated_ind = 'N' THEN 'false'
          ELSE NULL END                                 AS estimated_ind
   -- THE.smp_mix_gen_qlty has no audit columns; inherit from the parent seedlot.
   , REPLACE(sl.entry_userid, '@', '\')                 AS entry_userid
   , CAST(FROM_TZ(CAST(sl.entry_timestamp AS TIMESTAMP), 'America/Los_Angeles') AT TIME ZONE 'UTC' AS TIMESTAMP) AS entry_timestamp
   , REPLACE(sl.update_userid, '@', '\')                AS update_userid
   , CAST(FROM_TZ(CAST(sl.update_timestamp AS TIMESTAMP), 'America/Los_Angeles') AT TIME ZONE 'UTC' AS TIMESTAMP) AS update_timestamp
   , s.revision_count                                   AS revision_count
FROM the.smp_mix_gen_qlty s
JOIN the.seedlot sl
  ON sl.seedlot_number = s.seedlot_number
WHERE s.seedlot_number = :seedlot_number
