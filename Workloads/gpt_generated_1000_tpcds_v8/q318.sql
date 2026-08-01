WITH base AS (
  SELECT
    ws.ws_order_number,
    ws.ws_ext_ship_cost,
    ws.ws_sold_date_sk,
    c.c_preferred_cust_flag,
    c.c_birth_year,
    ca.ca_state,
    w.w_state,
    ib.ib_upper_bound,
    hd.hd_vehicle_count
  FROM web_sales ws
  FULL OUTER JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
  LEFT JOIN customer_address ca
    ON ws.ws_bill_addr_sk = ca.ca_address_sk
  LEFT JOIN household_demographics hd
    ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE c.c_preferred_cust_flag = 'Y'
    AND ib.ib_upper_bound >= 120000
    AND ws.ws_ext_ship_cost > 500
    AND w.w_state = 'CA'
    AND hd.hd_vehicle_count >= 2
    AND c.c_birth_year BETWEEN 1960 AND 1980
),
agg AS (
  SELECT
    ca_state,
    w_state,
    SUM(ws_ext_ship_cost) AS total_ship_cost,
    COUNT(DISTINCT ws_order_number) AS distinct_orders,
    SUM(DISTINCT ws_ext_ship_cost) AS distinct_ship_cost_sum,
    AVG(ws_ext_ship_cost) AS avg_ship_cost
  FROM base
  GROUP BY GROUPING SETS (
    (ca_state, w_state),
    (ca_state),
    (w_state),
    ()
  )
  HAVING SUM(ws_ext_ship_cost) > 1000
)
SELECT
  ca_state,
  w_state,
  total_ship_cost,
  distinct_orders,
  distinct_ship_cost_sum,
  avg_ship_cost,
  LAG(total_ship_cost) OVER (PARTITION BY ca_state ORDER BY w_state) AS lag_total_ship_cost
FROM agg
ORDER BY total_ship_cost DESC
LIMIT 100
