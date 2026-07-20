--------------------------------------------------------------------------------
-- spar.seedlot_owner_quantity  <-  THE.seedlot_owner_quantity
--------------------------------------------------------------------------------
-- Oracle CLIENT_NUMBER / CLIENT_LOCN_CODE map to Postgres owner_client_number /
-- owner_locn_code. The Oracle-only QTY_* columns are not carried over.
--------------------------------------------------------------------------------
SELECT
     s.seedlot_number                                   AS seedlot_number
   , s.client_number                                    AS owner_client_number
   , s.client_locn_code                                 AS owner_locn_code
   , s.original_pct_owned                               AS original_pct_owned
   , s.original_pct_rsrvd                               AS original_pct_rsrvd
   , s.original_pct_srpls                               AS original_pct_srpls
   , s.method_of_payment_code                           AS method_of_payment_code
   , s.spar_fund_srce_code                              AS spar_fund_srce_code
   -- THE.seedlot_owner_quantity has no audit columns; inherit from the parent seedlot.
   , REPLACE(sl.entry_userid, '@', '\')                 AS entry_userid
   , CAST(FROM_TZ(CAST(sl.entry_timestamp AS TIMESTAMP), 'America/Los_Angeles') AT TIME ZONE 'UTC' AS TIMESTAMP) AS entry_timestamp
   , REPLACE(sl.update_userid, '@', '\')                AS update_userid
   , CAST(FROM_TZ(CAST(sl.update_timestamp AS TIMESTAMP), 'America/Los_Angeles') AT TIME ZONE 'UTC' AS TIMESTAMP) AS update_timestamp
   , s.revision_count                                   AS revision_count
FROM the.seedlot_owner_quantity s
JOIN the.seedlot sl
  ON sl.seedlot_number = s.seedlot_number
WHERE s.seedlot_number = :seedlot_number
