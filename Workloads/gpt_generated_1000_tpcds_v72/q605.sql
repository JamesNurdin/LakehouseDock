WITH store_monthly AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        CAST('store' AS varchar) AS channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY d.d_year, d.d_month_seq
),
web_monthly AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        CAST('web' AS varchar) AS channel
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2001
    GROUP BY d.d_year, d.d_month_seq
)
SELECT d_year, d_month_seq, total_sales, total_profit, channel
FROM store_monthly
UNION ALL
SELECT d_year, d_month_seq, total_sales, total_profit, channel
FROM web_monthly
ORDER BY d_year, d_month_seq, channel
LIMIT 100
