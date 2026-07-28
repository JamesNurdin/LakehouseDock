/* Goal: Compare daily total amounts from catalog returns, web returns, and web sales for the year 2001, rank each source by amount per day, and list the top 100 records. */
WITH catalog_ret AS (
    SELECT d.d_date AS dt,
           SUM(cr.cr_return_amount) AS total_amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_date
),
web_ret AS (
    SELECT d.d_date AS dt,
           SUM(wr.wr_return_amt) AS total_amount
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_date
),
web_sal AS (
    SELECT d.d_date AS dt,
           SUM(ws.ws_ext_sales_price) AS total_amount
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_date
),
combined AS (
    SELECT dt,
           'catalog_return' AS source,
           total_amount
    FROM catalog_ret
    UNION ALL
    SELECT dt,
           'web_return' AS source,
           total_amount
    FROM web_ret
    UNION ALL
    SELECT dt,
           'web_sales' AS source,
           total_amount
    FROM web_sal
)
SELECT DISTINCT
       dt,
       source,
       total_amount,
       ROW_NUMBER() OVER (PARTITION BY source ORDER BY total_amount DESC) AS rank_per_source
FROM combined
ORDER BY dt, source
LIMIT 100
