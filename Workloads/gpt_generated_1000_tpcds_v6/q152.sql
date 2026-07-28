WITH store_data AS (
    SELECT
        d.d_year AS year,
        'store' AS channel,
        CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_category,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE s.s_state = 'CA'
      AND d.d_year BETWEEN 2001 AND 2002
    GROUP BY d.d_year
),
web_data AS (
    SELECT
        d.d_year AS year,
        'web' AS channel,
        CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_category,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE ws.ws_ship_customer_sk IN (
        SELECT ws2.ws_ship_customer_sk
        FROM web_sales ws2
        JOIN date_dim d2 ON ws2.ws_ship_date_sk = d2.d_date_sk
        WHERE d2.d_fy_quarter_seq = 11
        LIMIT 10
    )
      AND d.d_year = 2002
    GROUP BY d.d_year
)
SELECT
    year,
    channel,
    profit_category,
    SUM(total_sales) AS total_sales,
    SUM(total_profit) AS total_profit
FROM (
    SELECT * FROM store_data
    UNION ALL
    SELECT * FROM web_data
) AS u
GROUP BY GROUPING SETS (
    (year, channel, profit_category),
    (year, channel),
    (year),
    ()
)
ORDER BY
    year ASC NULLS LAST,
    channel ASC NULLS LAST,
    profit_category ASC NULLS LAST
LIMIT 100
