WITH
  -- Pre‑aggregate store sales per customer and store
  ss_agg AS (
    SELECT
      ss_customer_sk,
      ss_store_sk,
      SUM(ss_net_paid) AS store_net_paid
    FROM store_sales
    GROUP BY ss_customer_sk, ss_store_sk
  ),
  -- Unnest street name words for each store
  street_words AS (
    SELECT
      s.s_store_sk,
      word
    FROM store s
    CROSS JOIN UNNEST(split(s.s_street_name, ' ')) AS t(word)
  ),
  -- Intersect two customer sets to obtain a focused segment
  intersect_customers AS (
    SELECT c.c_customer_sk
    FROM customer c
    WHERE c.c_birth_day = 9
    INTERSECT
    SELECT c.c_customer_sk
    FROM customer c
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    WHERE hd.hd_dep_count > 5
  )
SELECT
  s.s_store_id,
  w.w_warehouse_name,
  cp.cp_catalog_number,
  hd.hd_income_band_sk,
  ib.ib_lower_bound,
  SUM(cs.cs_net_paid) AS total_catalog_net_paid,
  SUM(ss_agg.store_net_paid) AS total_store_net_paid,
  COUNT(DISTINCT c.c_customer_id) AS unique_customers,
  AVG(CASE WHEN cs.cs_ext_discount_amt > 0 THEN cs.cs_ext_discount_amt / cs.cs_ext_sales_price ELSE 0 END) AS avg_discount_rate,
  CASE
    WHEN SUM(cs.cs_net_profit) > 100000 THEN 'HIGH'
    WHEN SUM(cs.cs_net_profit) > 50000 THEN 'MEDIUM'
    ELSE 'LOW'
  END AS profit_category,
  COUNT(DISTINCT sw.word) AS distinct_street_words
FROM catalog_sales cs
JOIN catalog_page cp
  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN customer c
  ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN intersect_customers ic
  ON ic.c_customer_sk = c.c_customer_sk
JOIN household_demographics hd
  ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN ship_mode sm
  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
  ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN inventory i
  ON i.inv_warehouse_sk = w.w_warehouse_sk
JOIN ss_agg
  ON ss_agg.ss_customer_sk = c.c_customer_sk
JOIN store s
  ON s.s_store_sk = ss_agg.ss_store_sk
JOIN street_words sw
  ON sw.s_store_sk = s.s_store_sk
WHERE
  s.s_county = 'Richland County' AND
  w.w_gmt_offset = -6.00 AND
  i.inv_quantity_on_hand > 200 AND
  c.c_birth_day = 9 AND
  ib.ib_upper_bound <= 60000 AND
  cs.cs_sold_date_sk = (
    SELECT MAX(cs2.cs_sold_date_sk)
    FROM catalog_sales cs2
    WHERE cs2.cs_sold_date_sk < 2452000
  ) AND
  EXISTS (
    SELECT 1
    FROM store_sales ss2
    WHERE ss2.ss_customer_sk = c.c_customer_sk
      AND ss2.ss_quantity > 5
  )
GROUP BY
  s.s_store_id,
  w.w_warehouse_name,
  cp.cp_catalog_number,
  hd.hd_income_band_sk,
  ib.ib_lower_bound
HAVING
  SUM(cs.cs_net_paid) > 10000
ORDER BY
  total_catalog_net_paid DESC
LIMIT 100
