WITH
  sampled_store_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
  ),
  call_center_hours AS (
    SELECT
      cc_call_center_sk,
      cc_name,
      split(cc_hours, ',') AS hours_arr
    FROM call_center
  ),
  call_center_unnested AS (
    SELECT
      cc.cc_call_center_sk,
      cc.cc_name,
      hour_val
    FROM call_center_hours cc
    CROSS JOIN UNNEST(cc.hours_arr) AS t(hour_val)
  ),
  store_ids_positive AS (
    SELECT s.s_store_id
    FROM store s
    JOIN sampled_store_sales ss ON ss.ss_store_sk = s.s_store_sk
    GROUP BY s.s_store_id
    HAVING SUM(ss.ss_net_paid) > 10000
  ),
  store_ids_negative AS (
    SELECT s.s_store_id
    FROM store s
    JOIN sampled_store_sales ss ON ss.ss_store_sk = s.s_store_sk
    GROUP BY s.s_store_id
    HAVING SUM(ss.ss_net_paid) < 0
  ),
  store_ids_excluded AS (
    SELECT * FROM store_ids_positive
    EXCEPT
    SELECT * FROM store_ids_negative
  ),
  store_ids_common AS (
    SELECT * FROM store_ids_positive
    INTERSECT
    SELECT * FROM store_ids_negative
  )
SELECT
  s.s_store_name,
  d.d_year,
  p.p_promo_name,
  COUNT(DISTINCT ss.ss_ticket_number) AS tickets,
  SUM(ss.ss_net_paid) AS total_net_paid,
  SUM(cr.cr_return_amount) AS total_return_amount,
  SUM(CASE WHEN cc_unnested.hour_val IS NOT NULL THEN 1 ELSE 0 END) AS hour_entries
FROM sampled_store_sales ss
RIGHT OUTER JOIN store s ON ss.ss_store_sk = s.s_store_sk
INNER JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
INNER JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
LEFT JOIN call_center_unnested cc_unnested ON cc.cc_call_center_sk = cc_unnested.cc_call_center_sk
WHERE s.s_store_id IN (SELECT s_store_id FROM store_ids_excluded)
GROUP BY s.s_store_name, d.d_year, p.p_promo_name
HAVING SUM(ss.ss_net_paid) > 0
ORDER BY total_net_paid DESC
LIMIT 100
