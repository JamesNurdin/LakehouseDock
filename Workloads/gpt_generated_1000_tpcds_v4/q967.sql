WITH catalog_ret_agg AS (
   SELECT
      cr.cr_catalog_page_sk,
      cr.cr_ship_mode_sk,
      SUM(cr.cr_return_amount) AS sum_cr_return_amount,
      COUNT(*) AS cnt_cr
   FROM catalog_returns cr
   JOIN date_dim d1 ON cr.cr_returned_date_sk = d1.d_date_sk
   JOIN time_dim t1 ON cr.cr_returned_time_sk = t1.t_time_sk
   WHERE d1.d_year = 2001
     AND d1.d_month_seq BETWEEN 1200 AND 1210
     AND t1.t_hour BETWEEN 9 AND 17
   GROUP BY cr.cr_catalog_page_sk, cr.cr_ship_mode_sk
)
SELECT
   cp.cp_department,
   sm.sm_type,
   CASE
      WHEN sr.sr_return_amt > (
          SELECT AVG(sr2.sr_return_amt)
          FROM store_returns sr2
          WHERE sr2.sr_item_sk = i.i_item_sk
      ) THEN 'High'
      ELSE 'Low'
   END AS return_level,
   COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt,
   SUM(cr_agg.sum_cr_return_amount) AS total_catalog_return_amount,
   SUM(sr.sr_return_amt) AS total_store_return_amount,
   SUM(cr_agg.sum_cr_return_amount + sr.sr_return_amt) AS combined_return_amount,
   MIN(sr.sr_return_amt) AS min_store_return_amt,
   MAX(sr.sr_return_amt) AS max_store_return_amt
FROM catalog_ret_agg cr_agg
JOIN catalog_page cp ON cr_agg.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cr_agg.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN date_dim d_store ON cp.cp_end_date_sk = d_store.d_date_sk
JOIN store_returns sr ON sr.sr_returned_date_sk = d_store.d_date_sk
JOIN time_dim t_store ON sr.sr_return_time_sk = t_store.t_time_sk
JOIN item i ON sr.sr_item_sk = i.i_item_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
WHERE cp.cp_department = 'Electronics'
  AND sm.sm_type = 'AIR'
  AND r.r_reason_desc = 'Damaged'
  AND i.i_manufact_id = 117
  AND d_store.d_year = 2001
  AND t_store.t_hour BETWEEN 9 AND 17
  AND i.i_units = 'Box'
GROUP BY
   cp.cp_department,
   sm.sm_type,
   CASE
      WHEN sr.sr_return_amt > (
          SELECT AVG(sr2.sr_return_amt)
          FROM store_returns sr2
          WHERE sr2.sr_item_sk = i.i_item_sk
      ) THEN 'High'
      ELSE 'Low'
   END
ORDER BY combined_return_amount DESC
LIMIT 100
