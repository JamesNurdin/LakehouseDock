SELECT
  d.d_year,
  d.d_month_seq,
  sm.sm_type AS ship_mode,
  hd.hd_income_band_sk,
  SUM(cs.cs_net_paid_inc_ship_tax) AS total_net_paid,
  COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers,
  REGEXP_EXTRACT(i.i_product_name, '(\\d{4})', 1) AS product_code_4digits,
  CONCAT(i.i_brand, ' ', i.i_color) AS brand_color
FROM catalog_sales cs
JOIN item i
  ON cs.cs_item_sk = i.i_item_sk
JOIN date_dim d
  ON cs.cs_sold_date_sk = d.d_date_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN household_demographics hd
  ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
WHERE REGEXP_LIKE(i.i_product_name, '\\d{4}')
  AND i.i_formulation LIKE '90%'
  AND d.d_year = 2001
GROUP BY
  d.d_year,
  d.d_month_seq,
  sm.sm_type,
  hd.hd_income_band_sk,
  REGEXP_EXTRACT(i.i_product_name, '(\\d{4})', 1),
  CONCAT(i.i_brand, ' ', i.i_color)
HAVING SUM(cs.cs_net_paid_inc_ship_tax) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
