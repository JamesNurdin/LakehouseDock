WITH web_summary AS (
  SELECT
    td.t_hour,
    'Web' AS source,
    SUM(ws.ws_net_profit) AS total_profit,
    COUNT(*) AS sales_cnt
  FROM web_sales ws
  JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
  JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
  WHERE sm.sm_carrier = 'FEDEX'
    AND wp.wp_autogen_flag = 'N'
    AND td.t_hour BETWEEN 8 AND 20
  GROUP BY td.t_hour
),
store_summary AS (
  SELECT
    td.t_hour,
    'Store' AS source,
    SUM(ss.ss_net_profit) AS total_profit,
    COUNT(*) AS sales_cnt
  FROM store_sales ss
  JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
  JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  WHERE ca.ca_state = 'CA'
    AND td.t_hour BETWEEN 8 AND 20
  GROUP BY td.t_hour
),
combined AS (
  SELECT * FROM web_summary
  UNION ALL
  SELECT * FROM store_summary
)
SELECT
  c.t_hour,
  c.source,
  c.total_profit,
  c.sales_cnt,
  CASE WHEN c.total_profit > (SELECT avg(ws_net_profit) FROM web_sales) THEN 'High' ELSE 'Low' END AS profit_category,
  ROW_NUMBER() OVER (PARTITION BY c.source ORDER BY c.total_profit DESC) AS profit_rank
FROM combined c
ORDER BY c.total_profit DESC
LIMIT 100
