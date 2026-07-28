WITH store_sales_ca AS (
  SELECT
    i.i_category AS category,
    s.s_state AS region,
    ss.ss_net_profit AS profit,
    ss.ss_quantity AS qty,
    'store' AS source
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  WHERE d.d_year = 2001
    AND s.s_state = 'CA'
),
web_sales_ca AS (
  SELECT
    i.i_category AS category,
    w.web_state AS region,
    ws.ws_net_profit AS profit,
    ws.ws_quantity AS qty,
    'web' AS source
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
  WHERE d.d_year = 2001
    AND w.web_state = 'CA'
)
SELECT
  t.category,
  t.region,
  t.source,
  SUM(t.profit) AS total_profit,
  SUM(t.qty) AS total_quantity
FROM (
  SELECT * FROM store_sales_ca
  UNION ALL
  SELECT * FROM web_sales_ca
) t
GROUP BY t.category, t.region, t.source
HAVING SUM(t.profit) > 1000
ORDER BY total_profit DESC
LIMIT 100
