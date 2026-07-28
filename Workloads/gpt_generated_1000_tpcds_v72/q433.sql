WITH store_totals AS (
    SELECT d.d_year AS year,
           d.d_month_seq AS month_seq,
           SUM(ss.ss_net_paid) AS total_sales,
           CAST('store' AS varchar) AS channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq
),
web_totals AS (
    SELECT d.d_year AS year,
           d.d_month_seq AS month_seq,
           SUM(ws.ws_net_paid) AS total_sales,
           CAST('web' AS varchar) AS channel
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_year, d.d_month_seq
)
SELECT *
FROM store_totals
UNION ALL
SELECT *
FROM web_totals
ORDER BY year, month_seq, channel
