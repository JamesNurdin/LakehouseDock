WITH
  site_sales AS (
    SELECT
      ws.ws_web_site_sk,
      w.web_state,
      w.web_city,
      ws.ws_ext_sales_price,
      ws.ws_net_profit,
      ws.ws_ext_discount_amt,
      ws.ws_quantity,
      ws.ws_order_number
    FROM web_sales ws
    JOIN web_site w
      ON ws.ws_web_site_sk = w.web_site_sk
    WHERE ws.ws_ext_sales_price > 5000
      AND ws.ws_quantity >= 2
      AND w.web_gmt_offset = -5.00
      AND w.web_mkt_class LIKE '%New%'
  ),
  agg_sales AS (
    SELECT
      ss.web_state,
      ss.web_city,
      SUM(ss.ws_ext_sales_price) AS total_sales,
      SUM(ss.ws_net_profit) AS total_profit,
      AVG(ss.ws_ext_discount_amt) AS avg_discount
    FROM site_sales ss
    GROUP BY ROLLUP (ss.web_state, ss.web_city)
    HAVING SUM(ss.ws_ext_sales_price) > 20000
  )
SELECT
  COALESCE(agg.web_state, 'ALL') AS web_state,
  COALESCE(agg.web_city, 'ALL') AS web_city,
  agg.total_sales,
  agg.total_profit,
  agg.avg_discount,
  CASE
    WHEN agg.total_profit > 100000 THEN 'HIGH'
    WHEN agg.total_profit > 50000 THEN 'MEDIUM'
    ELSE 'LOW'
  END AS profit_category,
  RANK() OVER (PARTITION BY agg.web_state ORDER BY agg.total_profit DESC) AS state_profit_rank,
  ROW_NUMBER() OVER (ORDER BY agg.total_profit DESC) AS overall_rank
FROM agg_sales agg
ORDER BY agg.total_profit DESC
LIMIT 100
