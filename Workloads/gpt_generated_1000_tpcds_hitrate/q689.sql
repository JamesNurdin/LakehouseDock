WITH
  sales AS (
    SELECT
      ca.ca_state,
      SUM(cs.cs_ext_sales_price) AS total_sales,
      SUM(cs.cs_net_profit) AS total_profit,
      CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE cs.cs_quantity > 1
    GROUP BY ca.ca_state
    HAVING SUM(cs.cs_ext_sales_price) > 1000
  ),
  returns AS (
    SELECT
      ca.ca_state,
      SUM(wr.wr_return_amt) AS total_returns,
      CASE WHEN SUM(wr.wr_return_amt) > 0 THEN 'HasReturn' ELSE 'NoReturn' END AS return_flag
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE ws.ws_quantity > 0
    GROUP BY ca.ca_state
    HAVING SUM(wr.wr_return_amt) > 500
  ),
  ship_modes AS (
    SELECT sm.sm_ship_mode_id, sm.sm_type
    FROM ship_mode sm
    WHERE sm.sm_type IN ('AIR', 'RAIL')
  )
SELECT *
FROM (
  SELECT
    s.ca_state,
    s.total_sales,
    s.total_profit,
    s.profit_flag,
    NULL AS total_returns,
    NULL AS return_flag,
    sm.sm_ship_mode_id,
    sm.sm_type
  FROM sales s
  CROSS JOIN ship_modes sm
  WHERE s.profit_flag = 'Profitable'
    AND s.total_sales NOT IN (
      SELECT ws.ws_ext_sales_price
      FROM web_sales ws
      WHERE ws.ws_net_paid > 2000
    )

  UNION ALL

  SELECT
    r.ca_state,
    NULL AS total_sales,
    NULL AS total_profit,
    NULL AS profit_flag,
    r.total_returns,
    r.return_flag,
    sm.sm_ship_mode_id,
    sm.sm_type
  FROM returns r
  CROSS JOIN ship_modes sm
  WHERE r.return_flag = 'HasReturn'
) final_result
ORDER BY ca_state, sm_ship_mode_id
LIMIT 100
