WITH united AS (
  SELECT 'web' AS source,
         d.d_year AS year,
         d.d_month_seq AS month,
         ws.ws_bill_customer_sk AS customer_sk,
         ws.ws_item_sk AS item_sk,
         ws.ws_ext_sales_price AS sales
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE d.d_year = (
    SELECT max(d2.d_year)
    FROM date_dim d2
    WHERE d2.d_current_month = 'Y'
  )
  UNION ALL
  SELECT 'store_return' AS source,
         d.d_year AS year,
         d.d_month_seq AS month,
         sr.sr_customer_sk AS customer_sk,
         sr.sr_item_sk AS item_sk,
         -sr.sr_return_amt AS sales
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  WHERE d.d_year = (
    SELECT max(d2.d_year)
    FROM date_dim d2
    WHERE d2.d_current_month = 'Y'
  )
),
aggregated AS (
  SELECT
    source,
    year,
    month,
    COUNT(DISTINCT customer_sk) AS distinct_customers,
    COUNT(DISTINCT item_sk) AS distinct_items,
    SUM(sales) AS total_sales
  FROM united
  GROUP BY CUBE (source, year, month)
)
SELECT
  source,
  year,
  month,
  distinct_customers,
  distinct_items,
  total_sales,
  ROW_NUMBER() OVER (PARTITION BY year ORDER BY total_sales DESC) AS sales_rank
FROM aggregated
WHERE source IS NOT NULL
ORDER BY year DESC, month DESC, total_sales DESC
LIMIT 100
