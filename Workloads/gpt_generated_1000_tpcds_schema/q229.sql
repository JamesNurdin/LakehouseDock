WITH cs_sample AS (
  SELECT *
  FROM catalog_sales
  TABLESAMPLE BERNOULLI (10)
  WHERE cs_sold_date_sk BETWEEN 2450845 AND 2451055
    AND cs_net_paid_inc_ship > 1000
),
ss_filtered AS (
  SELECT *
  FROM store_sales
  WHERE ss_sold_date_sk BETWEEN 2450845 AND 2451055
    AND ss_sales_price > 20
)
SELECT
  department,
  catalog_number,
  state,
  meal_time,
  SUM(ext_sales_price) AS total_sales,
  AVG(net_profit)       AS avg_profit,
  COUNT(*)              AS transaction_cnt,
  MIN(ext_sales_price) AS min_sales,
  MAX(ext_sales_price) AS max_sales
FROM (
  SELECT
    cp.cp_department                         AS department,
    cp.cp_catalog_number                     AS catalog_number,
    ca.ca_state                              AS state,
    t.t_meal_time                            AS meal_time,
    cs.cs_ext_sales_price                    AS ext_sales_price,
    cs.cs_net_profit                         AS net_profit,
    cs.cs_quantity                           AS quantity
  FROM cs_sample cs
  JOIN catalog_page cp        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN time_dim t             ON cs.cs_sold_time_sk    = t.t_time_sk
  JOIN store_sales ss         ON ss.ss_sold_time_sk    = t.t_time_sk
  JOIN store s                ON ss.ss_store_sk        = s.s_store_sk
  JOIN customer_address ca   ON cs.cs_bill_addr_sk    = ca.ca_address_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib         ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE cp.cp_type = 'C'
    AND t.t_meal_time = 'dinner'
    AND s.s_state = 'CA'
    AND cs.cs_quantity > 5

  UNION DISTINCT

  SELECT
    cp.cp_department,
    cp.cp_catalog_number,
    ca.ca_state,
    t.t_meal_time,
    ss.ss_ext_sales_price,
    ss.ss_net_profit,
    ss.ss_quantity
  FROM ss_filtered ss
  JOIN time_dim t            ON ss.ss_sold_time_sk    = t.t_time_sk
  JOIN store s               ON ss.ss_store_sk        = s.s_store_sk
  JOIN catalog_sales cs      ON cs.cs_sold_time_sk   = t.t_time_sk
  JOIN catalog_page cp       ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN customer_address ca   ON ss.ss_addr_sk         = ca.ca_address_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk    = hd.hd_demo_sk
  JOIN income_band ib        ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE ca.ca_state = 'TX'
    AND ib.ib_lower_bound >= 30000
    AND ss.ss_sales_price > 50
    AND t.t_meal_time = 'breakfast'
) u
GROUP BY GROUPING SETS (
  (department, catalog_number, state, meal_time),
  (department, catalog_number),
  (state, meal_time),
  ()
)
ORDER BY total_sales DESC
LIMIT 100
