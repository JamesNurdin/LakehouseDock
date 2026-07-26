WITH unified_sales AS (
  SELECT
    cs.cs_item_sk AS item_sk,
    cs.cs_sold_date_sk AS sold_date_sk,
    cs.cs_net_profit AS net_profit,
    cs.cs_bill_addr_sk AS addr_sk,
    'catalog' AS src
  FROM catalog_sales cs
  UNION ALL
  SELECT
    ws.ws_item_sk,
    ws.ws_sold_date_sk,
    ws.ws_net_profit,
    ws.ws_bill_addr_sk,
    'web' AS src
  FROM web_sales ws
),
item_monthly AS (
  SELECT
    item_sk,
    sold_date_sk,
    SUM(CASE WHEN src = 'catalog' THEN net_profit ELSE 0 END) AS catalog_profit,
    SUM(CASE WHEN src = 'web' THEN net_profit ELSE 0 END) AS web_profit,
    MAX(CASE WHEN src = 'catalog' THEN addr_sk END) AS catalog_addr_sk,
    MAX(CASE WHEN src = 'web' THEN addr_sk END) AS web_addr_sk
  FROM unified_sales
  GROUP BY item_sk, sold_date_sk
)
SELECT
  im.item_sk,
  im.sold_date_sk,
  im.catalog_profit,
  im.web_profit,
  (im.catalog_profit - im.web_profit) AS profit_diff,
  p.p_promo_name,
  ca_cat.ca_city AS catalog_city,
  ca_web.ca_city AS web_city,
  ROW_NUMBER() OVER (ORDER BY ABS(im.catalog_profit - im.web_profit) DESC) AS profit_diff_rank,
  CASE
    WHEN im.catalog_profit > im.web_profit THEN 'Catalog Better'
    WHEN im.web_profit > im.catalog_profit THEN 'Web Better'
    ELSE 'Equal'
  END AS better_channel
FROM item_monthly im
LEFT JOIN promotion p ON p.p_item_sk = im.item_sk
LEFT JOIN customer_address ca_cat ON im.catalog_addr_sk = ca_cat.ca_address_sk
LEFT JOIN customer_address ca_web ON im.web_addr_sk = ca_web.ca_address_sk
WHERE im.catalog_profit IS NOT NULL OR im.web_profit IS NOT NULL
ORDER BY profit_diff_rank
LIMIT 10
