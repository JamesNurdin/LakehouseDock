WITH sales_agg AS (
  SELECT
    c_bill.c_customer_sk AS customer_sk,
    ca_bill.ca_state AS billing_state,
    w.w_warehouse_name AS warehouse_name,
    tcs.t_hour AS hour_of_day,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(cs.cs_ext_sales_price) + SUM(ss.ss_ext_sales_price) AS total_sales,
    COUNT(DISTINCT cs.cs_order_number) AS num_catalog_orders,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_store_tickets
  FROM catalog_sales cs
  JOIN time_dim tcs ON cs.cs_sold_time_sk = tcs.t_time_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
  JOIN customer c_ship ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
  JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
  JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
  JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
  JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
  JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
  JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
  JOIN store_sales ss ON ss.ss_sold_time_sk = tcs.t_time_sk
  JOIN customer c_ss ON ss.ss_customer_sk = c_ss.c_customer_sk
  JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
  JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
  JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
  WHERE
    c_bill.c_birth_year BETWEEN 1950 AND 1990
    AND ca_bill.ca_state IN ('CA', 'TX', 'NY')
    AND ca_ship.ca_location_type = 'single family'
    AND hd_bill.hd_vehicle_count >= 2
    AND ib.ib_upper_bound > 50000
    AND tcs.t_hour BETWEEN 8 AND 12
    AND cs.cs_quantity > 1
    AND c_ship.c_preferred_cust_flag = 'Y'
    AND c_ss.c_preferred_cust_flag = 'Y'
  GROUP BY
    ROLLUP (c_bill.c_customer_sk, ca_bill.ca_state, w.w_warehouse_name, tcs.t_hour)
),
state_hour_agg AS (
  SELECT
    billing_state,
    hour_of_day,
    SUM(total_sales) AS sum_sales,
    AVG(total_sales) AS avg_sales,
    COUNT(*) AS grp_cnt
  FROM sales_agg
  WHERE billing_state IS NOT NULL AND hour_of_day IS NOT NULL
  GROUP BY billing_state, hour_of_day
)
SELECT
  sha.billing_state,
  sha.hour_of_day,
  sha.sum_sales,
  sha.avg_sales,
  t.metric_value,
  CASE t.metric_index
    WHEN 1 THEN 'sum_sales'
    WHEN 2 THEN 'avg_sales'
  END AS metric_type,
  (
    SELECT COUNT(*)
    FROM state_hour_agg sha2
    WHERE sha2.billing_state = sha.billing_state
      AND sha2.sum_sales > sha.sum_sales
  ) AS higher_sum_groups
FROM state_hour_agg sha
CROSS JOIN UNNEST(ARRAY[sha.sum_sales, sha.avg_sales]) WITH ORDINALITY AS t(metric_value, metric_index)
WHERE sha.sum_sales > (
  SELECT AVG(sha3.sum_sales)
  FROM state_hour_agg sha3
  WHERE sha3.billing_state = sha.billing_state
)
ORDER BY sha.sum_sales DESC, sha.billing_state
LIMIT 100
