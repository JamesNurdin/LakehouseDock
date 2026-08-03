WITH
  store_agg AS (
    SELECT
      d.d_year AS sale_year,
      i.i_category AS category,
      SUM(ss.ss_ext_sales_price) AS total_sales,
      COUNT(*) AS sales_cnt,
      CASE WHEN SUM(ss.ss_ext_sales_price) > 100000 THEN 'high' ELSE 'medium' END AS sales_level
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
    GROUP BY CUBE (d.d_year, i.i_category)
  ),
  web_agg AS (
    SELECT
      d.d_year AS sale_year,
      i.i_category AS category,
      SUM(ws.ws_ext_sales_price) AS total_sales,
      COUNT(*) AS sales_cnt,
      CASE WHEN SUM(ws.ws_ext_sales_price) > 200000 THEN 'high' ELSE 'medium' END AS sales_level
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
    GROUP BY CUBE (d.d_year, i.i_category)
  ),
  combined AS (
    SELECT sale_year, category, total_sales, sales_cnt, sales_level, 'store' AS channel
    FROM store_agg
    UNION ALL
    SELECT sale_year, category, total_sales, sales_cnt, sales_level, 'web'   AS channel
    FROM web_agg
  )
SELECT
  c.sale_year,
  c.category,
  c.channel,
  c.total_sales,
  c.sales_cnt,
  c.sales_level,
  ROW_NUMBER() OVER (PARTITION BY c.sale_year ORDER BY c.total_sales DESC) AS sales_rank,
  (SELECT AVG(cc.total_sales)
   FROM combined cc
   WHERE cc.sale_year = c.sale_year) AS avg_sales_year
FROM combined c
WHERE EXISTS (
  SELECT 1
  FROM combined c2
  WHERE c2.category = c.category
    AND c2.sales_level = 'high'
    AND c2.channel <> c.channel
)
ORDER BY c.sale_year DESC, c.total_sales DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
