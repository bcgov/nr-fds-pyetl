--------------------------------------------------------------------------------
-- spar.seedlot_parent_tree_smp_mix  <-  THE.seedlot_parent_tree_smp_mix
--------------------------------------------------------------------------------
-- Oracle SMP_MIX_VALUE maps to Postgres genetic_quality_value.
-- Target columns confirmed against bcgov/nr-spar common/init_db/init.sql; the
-- entry/update audit columns are NOT NULL in Postgres.
--------------------------------------------------------------------------------
SELECT
     s.seedlot_number                                   AS seedlot_number
   , s.parent_tree_id                                   AS parent_tree_id
   , s.genetic_type_code                                AS genetic_type_code
   , s.genetic_worth_code                               AS genetic_worth_code
   , s.smp_mix_value                                    AS genetic_quality_value
   -- THE.seedlot_parent_tree_smp_mix has no audit columns; inherit from the parent seedlot.
   , REPLACE(sl.entry_userid, '@', '\')                 AS entry_userid
   , CAST(FROM_TZ(CAST(sl.entry_timestamp AS TIMESTAMP), 'America/Los_Angeles') AT TIME ZONE 'UTC' AS TIMESTAMP) AS entry_timestamp
   , REPLACE(sl.update_userid, '@', '\')                AS update_userid
   , CAST(FROM_TZ(CAST(sl.update_timestamp AS TIMESTAMP), 'America/Los_Angeles') AT TIME ZONE 'UTC' AS TIMESTAMP) AS update_timestamp
   , s.revision_count                                   AS revision_count
FROM the.seedlot_parent_tree_smp_mix s
JOIN the.seedlot sl
  ON sl.seedlot_number = s.seedlot_number
WHERE s.seedlot_number = :seedlot_number
