WITH store_agg AS (
  SELECT d.d_year,
         i.i_category,
         SUM(ss.ss_net_paid) AS store_sales
  FROM date_dim d
  JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE d.d_year = 2001
  GROUP BY d.d_year, i.i_category
),
catalog_agg AS (
  SELECT d.d_year,
         i.i_category,
         SUM(cs.cs_net_paid) AS catalog_sales
  FROM date_dim d
  JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE d.d_year = 2001
  GROUP BY d.d_year, i.i_category
),
web_agg AS (
  SELECT d.d_year,
         i.i_category,
         SUM(ws.ws_net_paid) AS web_sales
  FROM date_dim d
  JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  WHERE d.d_year = 2001
  GROUP BY d.d_year, i.i_category
)
SELECT COALESCE(s.d_year, c.d_year, w.d_year) AS d_year,
       COALESCE(s.i_category, c.i_category, w.i_category) AS i_category,
       COALESCE(s.store_sales, 0) AS store_sales,
       COALESCE(c.catalog_sales, 0) AS catalog_sales,
       COALESCE(w.web_sales, 0) AS web_sales,
       COALESCE(s.store_sales, 0) + COALESCE(c.catalog_sales, 0) + COALESCE(w.web_sales, 0) AS total_sales
FROM store_agg s
FULL OUTER JOIN catalog_agg c
  ON s.d_year = c.d_year AND s.i_category = c.i_category
FULL OUTER JOIN web_agg w
  ON COALESCE(s.d_year, c.d_year) = w.d_year
     AND COALESCE(s.i_category, c.i_category) = w.i_category
ORDER BY total_sales DESC
LIMIT 20
