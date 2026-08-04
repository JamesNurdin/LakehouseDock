WITH
  store_sales_year AS (
    SELECT
      d.d_year AS d_year,
      i.i_category AS i_category,
      SUM(ss.ss_net_profit) AS store_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE EXISTS (
      SELECT 1
      FROM promotion p
      WHERE p.p_item_sk = i.i_item_sk
        AND p.p_channel_email = 'Y'
    )
    GROUP BY d.d_year, i.i_category
  ),
  catalog_sales_year AS (
    SELECT
      d.d_year AS d_year,
      i.i_category AS i_category,
      SUM(cs.cs_net_profit) AS catalog_profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE EXISTS (
      SELECT 1
      FROM promotion p
      WHERE p.p_item_sk = i.i_item_sk
        AND p.p_channel_email = 'Y'
    )
    GROUP BY d.d_year, i.i_category
  ),
  union_sales AS (
    SELECT d_year, i_category, store_profit AS profit, 'store' AS source
    FROM store_sales_year
    UNION ALL
    SELECT d_year, i_category, catalog_profit AS profit, 'catalog' AS source
    FROM catalog_sales_year
  ),
  inventory_by_year AS (
    SELECT
      d.d_year AS d_year,
      i.i_category AS i_category,
      SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, i.i_category
  )
SELECT
  COALESCE(us.d_year, ib.d_year) AS year,
  COALESCE(us.i_category, ib.i_category) AS category,
  SUM(CASE WHEN us.source = 'store' THEN us.profit ELSE 0 END) AS store_profit,
  SUM(CASE WHEN us.source = 'catalog' THEN us.profit ELSE 0 END) AS catalog_profit,
  ib.total_on_hand
FROM union_sales us
FULL OUTER JOIN inventory_by_year ib
  ON us.d_year = ib.d_year
 AND us.i_category = ib.i_category
GROUP BY
  COALESCE(us.d_year, ib.d_year),
  COALESCE(us.i_category, ib.i_category),
  ib.total_on_hand
ORDER BY year, category
LIMIT 100
