WITH
  store_agg AS (
    SELECT
      s.s_state AS state,
      SUM(ss.ss_net_profit) AS total_profit,
      COUNT(*) AS transaction_count,
      CASE
        WHEN SUM(ss.ss_net_profit) > 50000 THEN 'High'
        WHEN SUM(ss.ss_net_profit) > 20000 THEN 'Medium'
        ELSE 'Low'
      END AS profit_category,
      GROUPING(s.s_state) AS grp_state
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY GROUPING SETS ((s.s_state), ())
    HAVING SUM(ss.ss_net_profit) > 10000 OR GROUPING(s.s_state) = 1
  ),
  web_agg AS (
    SELECT
      w.w_state AS state,
      SUM(ws.ws_net_profit) AS total_profit,
      COUNT(*) AS transaction_count,
      CASE
        WHEN SUM(ws.ws_net_profit) > 75000 THEN 'High'
        WHEN SUM(ws.ws_net_profit) > 30000 THEN 'Medium'
        ELSE 'Low'
      END AS profit_category,
      GROUPING(w.w_state) AS grp_state
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    GROUP BY GROUPING SETS ((w.w_state), ())
    HAVING SUM(ws.ws_net_profit) > 15000 OR GROUPING(w.w_state) = 1
  ),
  intersect_states AS (
    SELECT DISTINCT state
    FROM store_agg
    WHERE state IS NOT NULL
    INTERSECT
    SELECT DISTINCT state
    FROM web_agg
    WHERE state IS NOT NULL
  )
SELECT
  i.state,
  CASE WHEN i.state IS NULL THEN 'ALL' ELSE i.state END AS region,
  COALESCE(s.total_profit, w.total_profit) AS total_profit,
  COALESCE(s.profit_category, w.profit_category) AS profit_category
FROM intersect_states i
LEFT JOIN store_agg s ON i.state = s.state AND s.grp_state = 0
LEFT JOIN web_agg w   ON i.state = w.state AND w.grp_state = 0
ORDER BY total_profit DESC
