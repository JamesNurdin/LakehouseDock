WITH
  filtered_items AS (
    SELECT i_item_sk,
           i_product_name,
           i_category,
           i_brand
    FROM item
    WHERE i_category = 'Sports'
  ),
  combined_sales AS (
    SELECT
      fi.i_item_sk,
      fi.i_product_name,
      'Catalog' AS sales_channel,
      SUM(cs.cs_net_profit) AS total_profit,
      CASE WHEN SUM(cs.cs_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_category
    FROM catalog_sales cs
    JOIN filtered_items fi ON cs.cs_item_sk = fi.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY fi.i_item_sk, fi.i_product_name
    UNION ALL
    SELECT
      fi.i_item_sk,
      fi.i_product_name,
      'Web' AS sales_channel,
      SUM(ws.ws_net_profit) AS total_profit,
      CASE WHEN SUM(ws.ws_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_category
    FROM web_sales ws
    JOIN filtered_items fi ON ws.ws_item_sk = fi.i_item_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY fi.i_item_sk, fi.i_product_name
  )
SELECT
  i_item_sk,
  i_product_name,
  sales_channel,
  total_profit,
  profit_category
FROM combined_sales
ORDER BY total_profit DESC
LIMIT 100
