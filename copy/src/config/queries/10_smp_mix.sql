--------------------------------------------------------------------------------
-- spar.smp_mix  <-  THE.smp_mix
--------------------------------------------------------------------------------
-- Target columns confirmed against bcgov/nr-spar common/init_db/init.sql.
-- parent_tree_number is NOT NULL in Postgres and is resolved from THE.parent_tree.
-- The nullable Postgres proportion column has no Oracle source and is left unset.
-- entry/update audit columns are NOT NULL in Postgres.
--------------------------------------------------------------------------------
SELECT
     s.seedlot_number                                   AS seedlot_number
   , s.parent_tree_id                                   AS parent_tree_id
   , pt.parent_tree_number                              AS parent_tree_number
   , s.amount_of_material                               AS amount_of_material
   -- THE.smp_mix has no audit columns; inherit from the parent seedlot.
   , REPLACE(sl.entry_userid, '@', '\')                 AS entry_userid
   , CAST(FROM_TZ(CAST(sl.entry_timestamp AS TIMESTAMP), 'America/Los_Angeles') AT TIME ZONE 'UTC' AS TIMESTAMP) AS entry_timestamp
   , REPLACE(sl.update_userid, '@', '\')                AS update_userid
   , CAST(FROM_TZ(CAST(sl.update_timestamp AS TIMESTAMP), 'America/Los_Angeles') AT TIME ZONE 'UTC' AS TIMESTAMP) AS update_timestamp
   , s.revision_count                                   AS revision_count
FROM the.smp_mix s
JOIN the.seedlot sl
  ON sl.seedlot_number = s.seedlot_number
LEFT JOIN the.parent_tree pt
       ON pt.parent_tree_id = s.parent_tree_id
WHERE s.seedlot_number = :seedlot_number
