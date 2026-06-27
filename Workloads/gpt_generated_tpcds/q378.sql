WITH catalog_sales_agg AS (
  SELECT
    d.d_year,
    sm.sm_ship_mode_id,
    cs.cs_net_profit,
    cs.cs_quantity,
    cs.cs_bill_customer_sk AS cust_sk
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
),
web_sales_agg AS (
  SELECT
    d.d_year,
    sm.sm_ship_mode_id,
    ws.ws_net_profit,
    ws.ws_quantity,
    ws.ws_bill_customer_sk AS cust_sk
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
),
catalog_returns_agg AS (
  SELECT
    d.d_year,
    sm.sm_ship_mode_id,
    cr.cr_net_loss,
    cr.cr_return_quantity,
    cr.cr_refunded_customer_sk AS cust_sk
  FROM catalog_returns cr
  JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
  JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
)

SELECT
  t.year,
  t.ship_mode_id,
  SUM(t.profit) AS total_profit,
  SUM(t.loss)   AS total_loss,
  COUNT(DISTINCT t.cust_sk) AS distinct_customers,
  AVG(t.qty)    AS avg_quantity
FROM (
  SELECT
    d_year AS year,
    sm_ship_mode_id AS ship_mode_id,
    cs_net_profit AS profit,
    CAST(0 AS decimal(7,2)) AS loss,
    cs_quantity AS qty,
    cust_sk
  FROM catalog_sales_agg

  UNION ALL

  SELECT
    d_year,
    sm_ship_mode_id,
    ws_net_profit,
    CAST(0 AS decimal(7,2)),
    ws_quantity,
    cust_sk
  FROM web_sales_agg

  UNION ALL

  SELECT
    d_year,
    sm_ship_mode_id,
    CAST(0 AS decimal(7,2)),
    cr_net_loss,
    cr_return_quantity,
    cust_sk
  FROM catalog_returns_agg
) t
GROUP BY t.year, t.ship_mode_id
ORDER BY t.year, t.ship_mode_id
