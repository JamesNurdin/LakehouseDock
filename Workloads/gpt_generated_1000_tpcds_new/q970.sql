WITH
sampled_catalog AS (
  SELECT *
  FROM catalog_returns
  WHERE cr_return_amount > 1000
),
full_returns AS (
  SELECT *
  FROM store_returns sr
  FULL OUTER JOIN web_returns wr
    ON sr.sr_returned_date_sk = wr.wr_returned_date_sk
   AND sr.sr_return_time_sk = wr.wr_returned_time_sk
   AND sr.sr_customer_sk = wr.wr_refunded_customer_sk
),
union_returns AS (
  SELECT cr_refunded_customer_sk AS cust_sk, cr_return_amount AS amount
  FROM sampled_catalog
  UNION
  SELECT sr_customer_sk, sr_return_amt
  FROM store_returns
),
intersect_customers AS (
  SELECT cust_sk FROM union_returns
  INTERSECT
  SELECT cr_returning_customer_sk FROM sampled_catalog
)
SELECT
  d.d_year,
  d.d_month_seq,
  CASE WHEN sc.cr_return_amount > 5000 THEN 'High' ELSE 'Low' END AS return_category,
  COUNT(DISTINCT sc.cr_order_number) AS num_orders,
  SUM(sc.cr_return_amount) AS total_return_amount,
  AVG(sc.cr_return_tax) AS avg_return_tax,
  MIN(sc.cr_return_amount) AS min_return_amount,
  MAX(sc.cr_return_amount) AS max_return_amount,
  SUM(CASE WHEN sc.cr_return_amount > 5000 THEN 1 ELSE 0 END) AS high_value_return_cnt
FROM sampled_catalog sc
JOIN date_dim d ON sc.cr_returned_date_sk = d.d_date_sk
JOIN time_dim t ON sc.cr_returned_time_sk = t.t_time_sk
JOIN customer c ON sc.cr_refunded_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON sc.cr_refunded_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON sc.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN call_center cc ON sc.cr_call_center_sk = cc.cc_call_center_sk
JOIN (SELECT * FROM catalog_page TABLESAMPLE BERNOULLI (10)) cp ON sc.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON sc.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON sc.cr_warehouse_sk = w.w_warehouse_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
LEFT JOIN full_returns fr ON fr.sr_returned_date_sk = d.d_date_sk
WHERE c.c_birth_month = 7
  AND ib.ib_lower_bound >= 50000
  AND d.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  AND c.c_customer_sk IN (SELECT cust_sk FROM intersect_customers)
GROUP BY d.d_year,
         d.d_month_seq,
         CASE WHEN sc.cr_return_amount > 5000 THEN 'High' ELSE 'Low' END
HAVING COUNT(*) > 10
ORDER BY d.d_year, d.d_month_seq
