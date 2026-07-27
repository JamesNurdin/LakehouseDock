WITH base AS (
  SELECT
    cc.cc_name,
    w.w_warehouse_name,
    sm.sm_type,
    r.r_reason_desc,
    t.t_meal_time,
    SUM(cs.cs_net_paid) AS total_sales,
    SUM(sr.sr_return_amt) AS total_returns,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    COUNT(DISTINCT sr.sr_ticket_number) AS num_returns,
    CASE
      WHEN SUM(cs.cs_net_paid) - SUM(sr.sr_return_amt) > 0 THEN 'PROFIT'
      ELSE 'LOSS'
    END AS profit_flag
  FROM catalog_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN store_returns sr ON sr.sr_return_time_sk = t.t_time_sk
  JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
  WHERE
    t.t_meal_time IN ('lunch', 'dinner')
    AND t.t_hour BETWEEN 12 AND 20
    AND cc.cc_state = 'CA'
    AND sm.sm_type = 'AIR'
    AND r.r_reason_desc NOT LIKE '%job%'
    AND w.w_country = 'United States'
  GROUP BY
    cc.cc_name,
    w.w_warehouse_name,
    sm.sm_type,
    r.r_reason_desc,
    t.t_meal_time
)
SELECT
  profit_flag,
  AVG(total_sales) AS avg_sales,
  AVG(total_returns) AS avg_returns,
  AVG(total_sales - total_returns) AS avg_net,
  COUNT(*) AS grp_count
FROM base
WHERE total_sales > 0
GROUP BY profit_flag
ORDER BY avg_net DESC
LIMIT 100
