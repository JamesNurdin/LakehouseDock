WITH combined AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        'store' AS channel,
        ss.ss_ext_sales_price AS sales,
        ss.ss_net_profit AS profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
    UNION ALL
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        'web' AS channel,
        ws.ws_ext_sales_price AS sales,
        ws.ws_net_profit AS profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE d.d_year = 2001
)
SELECT
    year,
    month,
    channel,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit,
    GROUPING(year)   AS g_year,
    GROUPING(month)  AS g_month,
    GROUPING(channel) AS g_channel
FROM combined
GROUP BY GROUPING SETS (
    (year, month, channel),
    (year, month),
    (year),
    ()
)
ORDER BY
    year,
    month,
    channel
LIMIT 100
