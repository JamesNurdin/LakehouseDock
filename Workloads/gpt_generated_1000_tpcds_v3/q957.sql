WITH store_data AS (
  SELECT
    d.d_date AS sale_date,
    i.i_item_id AS item_id,
    i.i_product_name AS product_name,
    ss.ss_net_profit AS net_profit,
    'store' AS source,
    CASE WHEN ss.ss_net_profit >= 500 THEN 'High' ELSE 'Low' END AS profit_category
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE d.d_year = 2001
    AND i.i_category = 'Sports'
),
catalog_data AS (
  SELECT
    d.d_date AS sale_date,
    i.i_item_id AS item_id,
    i.i_product_name AS product_name,
    cs.cs_net_profit AS net_profit,
    'catalog' AS source,
    CASE WHEN cs.cs_net_profit >= 500 THEN 'High' ELSE 'Low' END AS profit_category
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE d.d_year = 2001
    AND i.i_category = 'Sports'
)
SELECT
  sale_date,
  item_id,
  product_name,
  net_profit,
  source,
  profit_category,
  ROW_NUMBER() OVER (PARTITION BY source ORDER BY net_profit DESC) AS rank_within_source,
  ROW_NUMBER() OVER (ORDER BY net_profit DESC) AS overall_rank
FROM (
  SELECT * FROM store_data
  UNION ALL
  SELECT * FROM catalog_data
) combined
ORDER BY net_profit DESC
LIMIT 100
