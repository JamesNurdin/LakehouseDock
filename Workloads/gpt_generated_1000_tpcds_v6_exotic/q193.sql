WITH joined_data AS (
  SELECT
    cs.cs_order_number,
    cs.cs_net_paid_inc_ship_tax,
    cs.cs_net_profit,
    c.c_customer_id,
    c.c_preferred_cust_flag,
    sm.sm_ship_mode_id,
    sm.sm_type,
    w.w_warehouse_id,
    w.w_zip,
    td.t_time_id,
    td.t_minute,
    td.t_second,
    ws.ws_order_number
  FROM catalog_sales cs
  JOIN time_dim td
    ON cs.cs_sold_time_sk = td.t_time_sk
  JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN web_sales ws
    ON ws.ws_sold_time_sk = td.t_time_sk
  WHERE td.t_minute IN (9, 14)
    AND td.t_second = 2
    AND w.w_zip = '35709'
    AND sm.sm_type = 'AIR'
    AND c.c_preferred_cust_flag = 'Y'
    AND cs.cs_net_paid_inc_ship_tax > 1000
)
SELECT
  jd.c_customer_id,
  jd.w_warehouse_id,
  jd.sm_ship_mode_id,
  jd.t_time_id,
  CASE
    WHEN jd.cs_net_profit > 500 THEN 'HIGH'
    WHEN jd.cs_net_profit > 0 THEN 'MEDIUM'
    ELSE 'LOW'
  END AS profit_category,
  SUM(jd.cs_net_paid_inc_ship_tax) AS total_paid,
  COUNT(DISTINCT jd.ws_order_number) AS distinct_web_orders,
  ROW_NUMBER() OVER (PARTITION BY jd.w_warehouse_id ORDER BY SUM(jd.cs_net_paid_inc_ship_tax) DESC) AS warehouse_rank
FROM joined_data jd
GROUP BY
  jd.c_customer_id,
  jd.w_warehouse_id,
  jd.sm_ship_mode_id,
  jd.t_time_id,
  CASE
    WHEN jd.cs_net_profit > 500 THEN 'HIGH'
    WHEN jd.cs_net_profit > 0 THEN 'MEDIUM'
    ELSE 'LOW'
  END
HAVING SUM(jd.cs_net_paid_inc_ship_tax) > 5000
ORDER BY profit_category DESC, warehouse_rank ASC, total_paid DESC
LIMIT 100
