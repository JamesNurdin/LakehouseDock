WITH a AS (
  SELECT d.d_year AS year,
         i.i_brand AS brand,
         i.i_category AS category,
         SUM(cs.cs_net_profit) AS metric,
         CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
         (SELECT MAX(d2.d_year) FROM date_dim d2) AS extra_year
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 2000 AND 2002
  GROUP BY CUBE (d.d_year, i.i_brand, i.i_category)
),

b AS (
  SELECT d.d_year AS year,
         i.i_brand AS brand,
         i.i_category AS category,
         t.val AS metric,
         CASE WHEN t.val > 0 THEN 'Positive' ELSE 'NonPositive' END AS profit_flag,
         (SELECT MIN(d3.d_year) FROM date_dim d3) AS extra_year
  FROM (
        SELECT ss.ss_sold_date_sk,
               ss.ss_item_sk,
               ss.ss_quantity,
               ss.ss_sales_price
        FROM store_sales ss
       ) ss
  FULL OUTER JOIN (
        SELECT inv.inv_date_sk,
               inv.inv_item_sk,
               inv.inv_quantity_on_hand
        FROM inventory inv
       ) inv
    ON ss.ss_sold_date_sk = inv.inv_date_sk
   AND ss.ss_item_sk = inv.inv_item_sk
  JOIN date_dim d
    ON COALESCE(ss.ss_sold_date_sk, inv.inv_date_sk) = d.d_date_sk
  JOIN item i
    ON COALESCE(ss.ss_item_sk, inv.inv_item_sk) = i.i_item_sk
  CROSS JOIN UNNEST(ARRAY[CAST(ss.ss_quantity AS decimal(10,2)), CAST(inv.inv_quantity_on_hand AS decimal(10,2))]) AS t(val)
  WHERE d.d_year = 2001
  GROUP BY CUBE (d.d_year, i.i_brand, i.i_category), t.val
)
SELECT year, brand, category, metric, profit_flag, extra_year
FROM a
UNION ALL
SELECT year, brand, category, metric, profit_flag, extra_year
FROM b
ORDER BY year DESC
LIMIT 100
