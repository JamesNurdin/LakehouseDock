WITH base_data AS (
  SELECT
    c.c_customer_sk,
    c.c_customer_id,
    c.c_birth_year,
    sr.sr_net_loss,
    sr.sr_return_amt_inc_tax,
    s.s_state,
    s.s_store_name,
    cs.cs_quantity,
    cs.cs_ext_sales_price,
    cs.cs_net_profit,
    sm.sm_ship_mode_id AS ship_mode_id,
    sm.sm_carrier,
    ws.ws_ext_tax,
    ws.ws_ext_ship_cost,
    ws.ws_net_profit
  FROM
    tpcds.customer c
    JOIN tpcds.store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
    JOIN tpcds.store s ON sr.sr_store_sk = s.s_store_sk
    JOIN tpcds.catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
      AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE
    sr.sr_net_loss > 500
    AND cs.cs_quantity BETWEEN 1 AND 10
    AND cs.cs_ext_sales_price > 1000
    AND sm.sm_carrier IN ('UPS', 'DHL')
    AND s.s_state = 'CA'
    AND c.c_birth_year BETWEEN 1950 AND 1970
    AND ws.ws_ext_tax < 100
    AND ws.ws_ext_ship_cost > 500
),
profit_agg AS (
  SELECT
    ship_mode_id,
    s_state,
    SUM(cs_net_profit + ws_net_profit) AS net_amount,
    COUNT(DISTINCT c_customer_id) AS distinct_customers
  FROM
    base_data
  GROUP BY
    ship_mode_id,
    s_state
),
loss_agg AS (
  SELECT
    ship_mode_id,
    s_state,
    -SUM(sr_net_loss) AS net_amount,
    0 AS distinct_customers
  FROM
    base_data
  GROUP BY
    ship_mode_id,
    s_state
),
combined AS (
  SELECT * FROM profit_agg
  UNION ALL
  SELECT * FROM loss_agg
),
final_agg AS (
  SELECT
    ship_mode_id,
    s_state,
    SUM(net_amount) AS total_net,
    SUM(distinct_customers) AS total_customers
  FROM
    combined
  GROUP BY
    ship_mode_id,
    s_state
)
SELECT
  ship_mode_id,
  s_state,
  total_net,
  total_customers,
  CASE WHEN total_net > 0 THEN 'Profit' ELSE 'Loss' END AS net_category
FROM
  final_agg
ORDER BY
  total_net DESC
LIMIT 100
