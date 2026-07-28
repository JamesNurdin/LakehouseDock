WITH sales_agg AS (
  SELECT
    ss.ss_store_sk AS store_sk,
    s.s_store_name AS store_name,
    d.d_year AS year,
    p.p_promo_id AS promo_id,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_transactions
  FROM store_sales ss
  JOIN date_dim d
    ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
  JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
   AND sr.sr_item_sk = ss.ss_item_sk
  LEFT JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = d.d_date_sk
  LEFT JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
  LEFT JOIN inventory inv
    ON inv.inv_date_sk = d.d_date_sk
  LEFT JOIN warehouse w
    ON w.w_warehouse_sk = cr.cr_warehouse_sk
  LEFT JOIN catalog_page cp
    ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
  LEFT JOIN reason r
    ON r.r_reason_sk = COALESCE(sr.sr_reason_sk, cr.cr_reason_sk, wr.wr_reason_sk)
  LEFT JOIN web_page wp
    ON wp.wp_web_page_sk = wr.wr_web_page_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
    AND s.s_state IN ('CA', 'TX')
    AND p.p_discount_active = 'Y'
    AND hd.hd_vehicle_count >= 1
    AND w.w_city = 'Seattle'
  GROUP BY GROUPING SETS (
    (ss.ss_store_sk, s.s_store_name, d.d_year, p.p_promo_id),
    (ss.ss_store_sk, s.s_store_name, d.d_year),
    (ss.ss_store_sk, s.s_store_name),
    ()
  )
)
SELECT
  store_sk,
  store_name,
  year,
  promo_id,
  total_sales,
  distinct_transactions,
  (SELECT AVG(sa2.total_sales)
     FROM sales_agg sa2
     WHERE sa2.store_sk = sales_agg.store_sk) AS avg_store_sales,
  CASE
    WHEN promo_id IS NULL AND year IS NULL THEN 'Subtotal All Stores'
    WHEN promo_id IS NULL THEN 'Subtotal Store-Year'
    WHEN year IS NULL THEN 'Subtotal Store'
    ELSE 'Detail'
  END AS row_type
FROM sales_agg
WHERE total_sales > 10000
ORDER BY store_name, year, promo_id
LIMIT 100
