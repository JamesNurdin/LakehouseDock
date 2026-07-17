WITH store_sales_data AS (
    SELECT d.d_date AS sale_date,
           ss.ss_ext_sales_price AS sales_amount,
           'store' AS channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND ss.ss_ext_sales_price > 1000
),
web_sales_data AS (
    SELECT d.d_date AS sale_date,
           ws.ws_ext_sales_price AS sales_amount,
           'web' AS channel
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND ws.ws_ext_sales_price > 1000
)
SELECT sale_date,
       channel,
       SUM(sales_amount) AS total_sales
FROM (
    SELECT sale_date, sales_amount, channel FROM store_sales_data
    UNION ALL
    SELECT sale_date, sales_amount, channel FROM web_sales_data
) AS combined
GROUP BY sale_date, channel
ORDER BY sale_date, channel
