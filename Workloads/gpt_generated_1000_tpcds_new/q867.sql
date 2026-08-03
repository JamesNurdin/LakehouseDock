SELECT
  year,
  category,
  word,
  total_sales,
  SUM(total_sales) OVER (PARTITION BY category ORDER BY year ROWS UNBOUNDED PRECEDING) AS running_sales,
  (SELECT MAX(yearly_sales) FROM (
       SELECT d2.d_year AS yr, SUM(ws2.ws_ext_sales_price) AS yearly_sales
       FROM web_sales ws2
       JOIN date_dim d2 ON ws2.ws_sold_date_sk = d2.d_date_sk
       GROUP BY d2.d_year
   ) sub) AS max_yearly_sales
FROM (
  -- First sub‑query: sales by year and item category
  SELECT
    d.d_year AS year,
    i.i_category AS category,
    NULL AS word,
    SUM(ws.ws_ext_sales_price) AS total_sales
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2001
  GROUP BY d.d_year, i.i_category
  HAVING SUM(ws.ws_ext_sales_price) > 10000

  UNION ALL

  -- Second sub‑query: explode product name into words and aggregate sales per word
  SELECT
    d.d_year AS year,
    NULL AS category,
    w.word AS word,
    SUM(ws.ws_ext_sales_price) AS total_sales
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  CROSS JOIN UNNEST(SPLIT(i.i_product_name, ' ')) AS w(word)
  WHERE d.d_year BETWEEN 1999 AND 2001
  GROUP BY d.d_year, w.word
  HAVING SUM(ws.ws_ext_sales_price) > 5000
) u
ORDER BY year DESC, total_sales DESC
OFFSET 10
LIMIT 100
