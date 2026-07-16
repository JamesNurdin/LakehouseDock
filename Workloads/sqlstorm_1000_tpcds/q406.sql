WITH sales_by_channel AS (
  SELECT 'store' AS channel,
         s.s_store_sk AS store_sk,
         s.s_store_name AS store_name,
         d.d_year AS sale_year,
         i.i_category AS category,
         SUM(ss.ss_net_profit) AS net_profit,
         SUM(ss.ss_quantity) AS quantity,
         AVG(ss.ss_net_paid) AS avg_paid,
         COUNT(DISTINCT ss.ss_customer_sk) AS cust_count,
         SUM(CASE WHEN ss.ss_quantity > 5 THEN 1 ELSE 0 END) AS high_qty_txns
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  LEFT JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  LEFT JOIN item i ON ss.ss_item_sk = i.i_item_sk
  GROUP BY s.s_store_sk, s.s_store_name, d.d_year, i.i_category

  UNION ALL

  SELECT 'web' AS channel,
         ws.ws_web_page_sk AS store_sk,
         wp.wp_url AS store_name,
         d.d_year AS sale_year,
         i.i_category AS category,
         SUM(ws.ws_net_profit) AS net_profit,
         SUM(ws.ws_quantity) AS quantity,
         AVG(ws.ws_net_paid) AS avg_paid,
         COUNT(DISTINCT ws.ws_bill_customer_sk) AS cust_count,
         SUM(CASE WHEN ws.ws_quantity > 5 THEN 1 ELSE 0 END) AS high_qty_txns
  FROM web_sales ws
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
  GROUP BY ws.ws_web_page_sk, wp.wp_url, d.d_year, i.i_category

  UNION ALL

  SELECT 'catalog' AS channel,
         cs.cs_call_center_sk AS store_sk,
         cc.cc_name AS store_name,
         d.d_year AS sale_year,
         i.i_category AS category,
         SUM(cs.cs_net_profit) AS net_profit,
         SUM(cs.cs_quantity) AS quantity,
         AVG(cs.cs_net_paid) AS avg_paid,
         COUNT(DISTINCT cs.cs_bill_customer_sk) AS cust_count,
         SUM(CASE WHEN cs.cs_quantity > 5 THEN 1 ELSE 0 END) AS high_qty_txns
  FROM catalog_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  LEFT JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  LEFT JOIN item i ON cs.cs_item_sk = i.i_item_sk
  GROUP BY cs.cs_call_center_sk, cc.cc_name, d.d_year, i.i_category
),

store_rankings AS (
  SELECT
    channel,
    store_sk,
    store_name,
    sale_year,
    category,
    net_profit,
    quantity,
    avg_paid,
    cust_count,
    high_qty_txns,
    RANK() OVER (PARTITION BY channel, sale_year ORDER BY net_profit DESC) AS profit_rank,
    SUM(net_profit) OVER (PARTITION BY channel) AS channel_total_profit,
    (net_profit * 100.0) / NULLIF(SUM(net_profit) OVER (PARTITION BY channel), 0) AS profit_pct_of_channel
  FROM sales_by_channel
),

category_year_avg AS (
  SELECT
    channel,
    sale_year,
    category,
    AVG(net_profit) AS avg_category_profit
  FROM sales_by_channel
  GROUP BY channel, sale_year, category
)

SELECT
  sr.channel,
  sr.sale_year,
  sr.store_name,
  COALESCE(sr.category, 'UNKNOWN') AS category,
  sr.net_profit,
  sr.quantity,
  sr.avg_paid,
  sr.cust_count,
  sr.high_qty_txns,
  sr.profit_rank,
  ROUND(sr.profit_pct_of_channel, 2) AS profit_pct_of_channel,
  CASE
    WHEN sr.net_profit > ca.avg_category_profit THEN 'ABOVE_AVG'
    WHEN sr.net_profit < ca.avg_category_profit THEN 'BELOW_AVG'
    ELSE 'EQUAL_AVG'
  END AS profit_vs_category_avg,
  (SELECT SUM(sb3.net_profit)
     FROM sales_by_channel sb3
    WHERE sb3.channel = sr.channel
      AND sb3.sale_year = sr.sale_year
      AND sb3.category = sr.category) AS category_year_total_profit,
  CONCAT(sr.channel, '-', CAST(sr.store_sk AS VARCHAR), '-', CAST(sr.sale_year AS VARCHAR)) AS composite_key
FROM store_rankings sr
LEFT JOIN category_year_avg ca
  ON sr.channel = ca.channel
  AND sr.sale_year = ca.sale_year
  AND sr.category = ca.category
WHERE sr.profit_rank <= 10
  AND sr.net_profit IS NOT NULL
  AND sr.net_profit <> 0
  AND (sr.store_name LIKE '%Inc%' OR sr.store_name IS NULL)
ORDER BY sr.channel, sr.profit_rank
