WITH catalog_2022 AS (
  SELECT
    cs.cs_item_sk,
    sum(cs.cs_net_profit) AS catalog_profit
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2022
  GROUP BY cs.cs_item_sk
),
store_2022 AS (
  SELECT
    ss.ss_item_sk,
    sum(ss.ss_net_profit) AS store_profit
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2022
  GROUP BY ss.ss_item_sk
),
item_agg AS (
  SELECT
    i.i_item_sk,
    i.i_item_id AS item_id,
    i.i_product_name AS product_name,
    i.i_item_desc AS item_desc,
    i.i_color AS color,
    i.i_size AS size,
    coalesce(c.catalog_profit, 0) + coalesce(s.store_profit, 0) AS total_profit,
    regexp_extract(i.i_item_desc, '([0-9]+)', 1) AS code,
    concat(i.i_color, '-', i.i_size) AS color_size
  FROM item i
  LEFT JOIN catalog_2022 c ON c.cs_item_sk = i.i_item_sk
  LEFT JOIN store_2022 s ON s.ss_item_sk = i.i_item_sk
  WHERE regexp_like(i.i_item_desc, '[0-9]{3}')
    AND i.i_color LIKE '%blue%'
    AND EXISTS (
      SELECT 1
      FROM catalog_sales cs2
      JOIN call_center cc ON cs2.cs_call_center_sk = cc.cc_call_center_sk
      JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
      WHERE cs2.cs_item_sk = i.i_item_sk
        AND cc.cc_class = 'large'
        AND d2.d_year = 2022
    )
    AND NOT EXISTS (
      SELECT 1
      FROM web_sales ws
      JOIN date_dim dw ON ws.ws_sold_date_sk = dw.d_date_sk
      WHERE ws.ws_item_sk = i.i_item_sk
        AND dw.d_year = 2022
    )
)
SELECT
  ia.item_id,
  ia.product_name,
  ia.item_desc,
  ia.code,
  ia.color_size,
  ia.total_profit,
  (SELECT avg(total_profit) FROM item_agg) AS avg_total_profit_all_items
FROM item_agg ia
ORDER BY ia.total_profit DESC
LIMIT 100
