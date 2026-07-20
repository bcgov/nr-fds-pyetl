--------------------------------------------------------------------------------
-- spar.seedlot_parent_tree  <-  THE.seedlot_parent_tree
--------------------------------------------------------------------------------
-- Target columns confirmed against bcgov/nr-spar common/init_db/init.sql.
-- parent_tree_number is NOT NULL in Postgres and is resolved from THE.parent_tree
-- (Oracle stores only parent_tree_id on the seedlot_parent_tree table).
-- The Oracle total_genetic_worth_contrib maps to the nullable Postgres column of
-- the same name.
--------------------------------------------------------------------------------
SELECT
     s.seedlot_number                                   AS seedlot_number
   , s.parent_tree_id                                   AS parent_tree_id
   , pt.parent_tree_number                              AS parent_tree_number
   , s.cone_count                                       AS cone_count
   , s.pollen_count                                     AS pollen_count
   , s.smp_success_pct                                  AS smp_success_pct
   , s.non_orchard_pollen_contam_pct                    AS non_orchard_pollen_contam_pct
   -- THE.seedlot_parent_tree has no audit columns; inherit from the parent seedlot.
   , REPLACE(sl.entry_userid, '@', '\')                 AS entry_userid
   , CAST(FROM_TZ(CAST(sl.entry_timestamp AS TIMESTAMP), 'America/Los_Angeles') AT TIME ZONE 'UTC' AS TIMESTAMP) AS entry_timestamp
   , REPLACE(sl.update_userid, '@', '\')                AS update_userid
   , CAST(FROM_TZ(CAST(sl.update_timestamp AS TIMESTAMP), 'America/Los_Angeles') AT TIME ZONE 'UTC' AS TIMESTAMP) AS update_timestamp
   , s.revision_count                                   AS revision_count
FROM the.seedlot_parent_tree s
JOIN the.seedlot sl
  ON sl.seedlot_number = s.seedlot_number
LEFT JOIN the.parent_tree pt
       ON pt.parent_tree_id = s.parent_tree_id
WHERE s.seedlot_number = :seedlot_number
