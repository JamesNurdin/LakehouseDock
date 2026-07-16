WITH store_sales_agg AS (
  SELECT d.d_year,
         i.i_category,
         i.i_brand,
         SUM(ss.ss_net_paid) AS store_sales,
         SUM(ss.ss_net_profit) AS store_profit
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1998 AND 2000
  GROUP BY d.d_year, i.i_category, i.i_brand
),
web_sales_agg AS (
  SELECT d.d_year,
         i.i_category,
         i.i_brand,
         SUM(ws.ws_net_paid) AS web_sales,
         SUM(ws.ws_net_profit) AS web_profit
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1998 AND 2000
  GROUP BY d.d_year, i.i_category, i.i_brand
),
catalog_sales_agg AS (
  SELECT d.d_year,
         i.i_category,
         i.i_brand,
         SUM(cs.cs_net_paid) AS catalog_sales,
         SUM(cs.cs_net_profit) AS catalog_profit
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1998 AND 2000
  GROUP BY d.d_year, i.i_category, i.i_brand
),
combined AS (
  SELECT COALESCE(ss.d_year, ws.d_year, cs.d_year) AS year,
         COALESCE(ss.i_category, ws.i_category, cs.i_category) AS category,
         COALESCE(ss.i_brand, ws.i_brand, cs.i_brand) AS brand,
         ss.store_sales,
         ws.web_sales,
         cs.catalog_sales,
         ss.store_profit,
         ws.web_profit,
         cs.catalog_profit
  FROM store_sales_agg ss
  FULL OUTER JOIN web_sales_agg ws
    ON ss.d_year = ws.d_year AND ss.i_category = ws.i_category AND ss.i_brand = ws.i_brand
  FULL OUTER JOIN catalog_sales_agg cs
    ON COALESCE(ss.d_year, ws.d_year) = cs.d_year
   AND COALESCE(ss.i_category, ws.i_category) = cs.i_category
   AND COALESCE(ss.i_brand, ws.i_brand) = cs.i_brand
)
SELECT year,
       category,
       brand,
       COALESCE(store_sales, 0) + COALESCE(web_sales, 0) + COALESCE(catalog_sales, 0) AS total_sales,
       COALESCE(store_profit, 0) + COALESCE(web_profit, 0) + COALESCE(catalog_profit, 0) AS total_profit,
       (COALESCE(store_profit, 0) + COALESCE(web_profit, 0) + COALESCE(catalog_profit, 0))
         / NULLIF(COALESCE(store_sales, 0) + COALESCE(web_sales, 0) + COALESCE(catalog_sales, 0), 0) AS profit_margin
FROM combined
WHERE COALESCE(store_sales, 0) + COALESCE(web_sales, 0) + COALESCE(catalog_sales, 0) > 0
ORDER BY total_sales DESC
LIMIT 100
