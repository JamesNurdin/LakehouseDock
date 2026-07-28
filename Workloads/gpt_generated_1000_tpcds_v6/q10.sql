WITH store_sales_agg AS (
  SELECT
    d.d_year AS year,
    i.i_category AS category,
    SUM(ss.ss_ext_sales_price) AS sales,
    CAST('Store' AS varchar) AS channel
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE d.d_holiday = 'N'
  GROUP BY d.d_year, i.i_category
),
web_sales_agg AS (
  SELECT
    d.d_year AS year,
    i.i_category AS category,
    SUM(ws.ws_ext_sales_price) AS sales,
    CAST('Web' AS varchar) AS channel
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  WHERE d.d_holiday = 'N'
  GROUP BY d.d_year, i.i_category
)
SELECT
  year,
  category,
  sales,
  channel
FROM (
  SELECT year, category, sales, channel FROM store_sales_agg
  UNION ALL
  SELECT year, category, sales, channel FROM web_sales_agg
) combined
ORDER BY year DESC, sales DESC
LIMIT 100
