WITH promo_sales AS (
  SELECT
    d.d_year AS year,
    d.d_month_seq AS month,
    'With Promo' AS sales_type,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    COUNT(*) AS order_cnt
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  WHERE ws.ws_promo_sk IS NOT NULL
    AND d.d_year BETWEEN 2000 AND 2002
  GROUP BY d.d_year, d.d_month_seq
),
no_promo_sales AS (
  SELECT
    d.d_year AS year,
    d.d_month_seq AS month,
    'No Promo' AS sales_type,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    COUNT(*) AS order_cnt
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE ws.ws_promo_sk IS NULL
    AND d.d_year BETWEEN 2000 AND 2002
  GROUP BY d.d_year, d.d_month_seq
),
combined AS (
  SELECT year, month, sales_type, total_sales, order_cnt FROM promo_sales
  UNION ALL
  SELECT year, month, sales_type, total_sales, order_cnt FROM no_promo_sales
)
SELECT
  year,
  month,
  sales_type,
  total_sales,
  order_cnt,
  SUM(total_sales) OVER (
    PARTITION BY sales_type
    ORDER BY year, month
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS running_total_sales
FROM combined
ORDER BY year, month, sales_type
LIMIT 100
