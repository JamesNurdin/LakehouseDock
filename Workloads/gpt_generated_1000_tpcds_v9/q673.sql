WITH year_filter AS (
    SELECT d_date_sk, d_year
    FROM date_dim
    WHERE d_year BETWEEN 2000 AND 2002
)
SELECT
    d_year,
    channel,
    total_sales,
    return_flag,
    sales_category
FROM (
    SELECT
        d.d_year,
        'store' AS channel,
        SUM(ss.ss_net_paid) AS total_sales,
        CASE WHEN EXISTS (
            SELECT 1
            FROM store_returns sr
            JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
            WHERE dr.d_year = d.d_year
        ) THEN 'Returned' ELSE 'No Return' END AS return_flag,
        CASE WHEN SUM(ss.ss_net_paid) > (
            SELECT AVG(year_total)
            FROM (
                SELECT SUM(ss2.ss_net_paid) AS year_total
                FROM store_sales ss2
                JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
                WHERE d2.d_year BETWEEN 2000 AND 2002
                GROUP BY d2.d_year
            ) t
        ) THEN 'High' ELSE 'Low' END AS sales_category
    FROM store_sales ss
    JOIN year_filter d ON ss.ss_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year

    UNION ALL

    SELECT
        d.d_year,
        'web' AS channel,
        SUM(ws.ws_net_paid) AS total_sales,
        CASE WHEN EXISTS (
            SELECT 1
            FROM web_returns wr
            JOIN date_dim dr ON wr.wr_returned_date_sk = dr.d_date_sk
            WHERE dr.d_year = d.d_year
        ) THEN 'Returned' ELSE 'No Return' END AS return_flag,
        CASE WHEN SUM(ws.ws_net_paid) > (
            SELECT AVG(year_total)
            FROM (
                SELECT SUM(ws2.ws_net_paid) AS year_total
                FROM web_sales ws2
                JOIN date_dim d2 ON ws2.ws_sold_date_sk = d2.d_date_sk
                WHERE d2.d_year BETWEEN 2000 AND 2002
                GROUP BY d2.d_year
            ) t
        ) THEN 'High' ELSE 'Low' END AS sales_category
    FROM web_sales ws
    JOIN year_filter d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY d.d_year
) combined
ORDER BY d_year, channel
LIMIT 100
