WITH date_filtered AS (
   SELECT d_date_sk, d_year, d_current_year, d_fy_week_seq, d_qoy
   FROM date_dim
   WHERE d_year BETWEEN 1999 AND 2001
     AND d_current_year = 'Y'
     AND d_fy_week_seq IN (4, 7, 13, 17)
     AND d_qoy = 1
),
call_center_filtered AS (
   SELECT cc_call_center_sk, cc_manager, cc_closed_date_sk, cc_gmt_offset
   FROM call_center
   WHERE cc_manager IN ('Ronnie Trinidad', 'Jack Little')
     AND cc_gmt_offset = -5.00
),
store_returns_filtered AS (
   SELECT sr_returned_date_sk, sr_store_sk, sr_reason_sk, sr_return_amt, sr_net_loss, sr_reversed_charge, sr_return_quantity
   FROM store_returns
   WHERE sr_net_loss > 80
     AND sr_reversed_charge >= 10
     AND sr_return_quantity >= 1
     AND sr_reason_sk NOT IN (
         SELECT sr_reason_sk FROM store_returns WHERE sr_return_quantity = 0
     )
),
union_set AS (
   SELECT sr.sr_store_sk AS store_sk,
          sr.sr_return_amt AS return_amt,
          cc.cc_manager AS manager,
          dd.d_year AS year
   FROM store_returns_filtered sr
   JOIN date_filtered dd ON sr.sr_returned_date_sk = dd.d_date_sk
   JOIN call_center_filtered cc ON cc.cc_closed_date_sk = dd.d_date_sk
   WHERE sr.sr_reason_sk = 19
   UNION ALL
   SELECT sr.sr_store_sk,
          sr.sr_return_amt,
          cc.cc_manager,
          dd.d_year
   FROM store_returns_filtered sr
   JOIN date_filtered dd ON sr.sr_returned_date_sk = dd.d_date_sk
   JOIN call_center_filtered cc ON cc.cc_closed_date_sk = dd.d_date_sk
   WHERE sr.sr_reason_sk = 7
)
SELECT t.store_sk,
       t.return_amt,
       t.manager,
       t.year,
       t.rn,
       t.total_return_for_store
FROM (
   SELECT us.store_sk,
          us.return_amt,
          us.manager,
          us.year,
          ROW_NUMBER() OVER (PARTITION BY us.manager ORDER BY us.return_amt DESC) AS rn,
          l.total_return_for_store
   FROM union_set us
   LEFT JOIN LATERAL (
       SELECT SUM(sr2.sr_return_amt) AS total_return_for_store
       FROM store_returns sr2
       WHERE sr2.sr_store_sk = us.store_sk
   ) l ON TRUE
) t
WHERE t.rn <= 5
ORDER BY t.year DESC, t.return_amt DESC
LIMIT 100
