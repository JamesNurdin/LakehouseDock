WITH raw_sales AS (
  -- Catalog sales side
  SELECT
    'Catalog' AS sales_channel,
    cp.cp_department AS dept,
    cs.cs_net_profit AS profit,
    c.c_customer_sk AS customer_sk
  FROM catalog_sales cs
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2450100
    AND EXISTS (
      SELECT 1 FROM web_sales ws
      WHERE ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2450100
    )

  UNION ALL

  -- Web sales side
  SELECT
    'Web' AS sales_channel,
    i.i_category AS dept,
    ws.ws_net_profit AS profit,
    c.c_customer_sk AS customer_sk
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  WHERE ws.ws_sold_date_sk BETWEEN 2450000 AND 2450100
    AND EXISTS (
      SELECT 1 FROM catalog_sales cs2
      WHERE cs2.cs_bill_customer_sk = c.c_customer_sk
        AND cs2.cs_sold_date_sk BETWEEN 2450000 AND 2450100
    )
)
SELECT
  sales_channel,
  dept,
  SUM(profit) AS total_profit,
  CASE
    WHEN SUM(profit) > 100000 THEN 'High'
    WHEN SUM(profit) > 50000 THEN 'Medium'
    ELSE 'Low'
  END AS profit_level
FROM raw_sales
GROUP BY GROUPING SETS (
  (sales_channel, dept),
  (sales_channel)
)
ORDER BY sales_channel, total_profit DESC
LIMIT 100
