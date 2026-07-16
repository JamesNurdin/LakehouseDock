WITH catalog AS (
  SELECT d.d_year AS year,
         i.i_category AS category,
         i.i_brand AS brand,
         SUM(cs.cs_net_paid) AS catalog_sales,
         COUNT(DISTINCT cs.cs_order_number) AS catalog_orders
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1998 AND 1999
  GROUP BY d.d_year, i.i_category, i.i_brand
),
store AS (
  SELECT d.d_year AS year,
         i.i_category AS category,
         i.i_brand AS brand,
         SUM(ss.ss_net_paid) AS store_sales,
         COUNT(DISTINCT ss.ss_ticket_number) AS store_orders
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1998 AND 1999
  GROUP BY d.d_year, i.i_category, i.i_brand
),
web AS (
  SELECT d.d_year AS year,
         i.i_category AS category,
         i.i_brand AS brand,
         SUM(ws.ws_net_paid) AS web_sales,
         COUNT(DISTINCT ws.ws_order_number) AS web_orders
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1998 AND 1999
  GROUP BY d.d_year, i.i_category, i.i_brand
)
SELECT COALESCE(c.year, s.year, w.year) AS year,
       COALESCE(c.category, s.category, w.category) AS category,
       COALESCE(c.brand, s.brand, w.brand) AS brand,
       c.catalog_sales,
       s.store_sales,
       w.web_sales,
       COALESCE(c.catalog_sales, 0) + COALESCE(s.store_sales, 0) + COALESCE(w.web_sales, 0) AS total_sales,
       c.catalog_orders,
       s.store_orders,
       w.web_orders,
       ROW_NUMBER() OVER (
         PARTITION BY COALESCE(c.year, s.year, w.year)
         ORDER BY COALESCE(c.catalog_sales, 0) + COALESCE(s.store_sales, 0) + COALESCE(w.web_sales, 0) DESC
       ) AS rank_in_year
FROM catalog c
FULL OUTER JOIN store s ON c.year = s.year AND c.category = s.category AND c.brand = s.brand
FULL OUTER JOIN web w ON COALESCE(c.year, s.year) = w.year
                     AND COALESCE(c.category, s.category) = w.category
                     AND COALESCE(c.brand, s.brand) = w.brand
ORDER BY year, total_sales DESC
