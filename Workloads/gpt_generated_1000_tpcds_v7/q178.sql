WITH base AS (
  SELECT
    cs.cs_sold_date_sk,
    cs.cs_sold_time_sk,
    cs.cs_bill_customer_sk,
    cs.cs_bill_hdemo_sk,
    cs.cs_bill_addr_sk,
    cs.cs_quantity,
    cs.cs_ext_sales_price,
    cs.cs_net_profit,
    cp.cp_catalog_number,
    cp.cp_catalog_page_number,
    cp.cp_type,
    w.w_warehouse_name,
    w.w_county,
    w.w_suite_number,
    ca.ca_state,
    hd.hd_demo_sk,
    hd.hd_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    t.t_hour,
    t.t_meal_time
  FROM catalog_sales cs
  JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
  WHERE cp.cp_catalog_number IN (3, 11, 20)
    AND ib.ib_lower_bound >= 50000
    AND w.w_county = 'Walker County'
    AND ca.ca_state = 'CA'
    AND t.t_hour BETWEEN 9 AND 17
    AND cp.cp_type = 'PROMO'
    AND t.t_meal_time = 'Lunch'
)
SELECT
  b.cp_catalog_number,
  b.cp_catalog_page_number,
  b.w_warehouse_name,
  b.w_county,
  COUNT(DISTINCT b.cs_bill_customer_sk) AS distinct_customers,
  SUM(b.cs_ext_sales_price) AS total_catalog_sales,
  COALESCE(SUM(ss.ss_ext_sales_price), 0) AS total_store_sales,
  AVG(b.cs_net_profit) AS avg_catalog_profit,
  COALESCE(AVG(ss.ss_net_profit), 0) AS avg_store_profit,
  MIN(b.cs_sold_date_sk) AS earliest_sold_date_sk,
  MAX(b.cs_sold_date_sk) AS latest_sold_date_sk
FROM base b
LEFT JOIN store_sales ss
  ON ss.ss_sold_time_sk = b.cs_sold_time_sk
     AND ss.ss_hdemo_sk = b.hd_demo_sk
     AND ss.ss_addr_sk = b.cs_bill_addr_sk
LEFT JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
     AND s.s_state = 'CA'
     AND s.s_number_employees > 50
GROUP BY
  b.cp_catalog_number,
  b.cp_catalog_page_number,
  b.w_warehouse_name,
  b.w_county
LIMIT 100
