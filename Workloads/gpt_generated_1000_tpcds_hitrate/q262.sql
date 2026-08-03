/*
Goal: Compare yearly net profit from web sales and store sales for the years 2000‑2001, enrich each record with a set of reason descriptions via a cross join, categorize profit levels with a CASE expression, and provide a scalar subquery showing the total profit across both channels.
*/
WITH web_profit AS (
    SELECT
        d.d_year AS year,
        SUM(ws.ws_net_profit) AS net_profit,
        'Web' AS channel
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2001
    GROUP BY d.d_year
),
store_profit AS (
    SELECT
        d.d_year AS year,
        SUM(ss.ss_net_profit) AS net_profit,
        'Store' AS channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2000 AND 2001
    GROUP BY d.d_year
),
year_reason AS (
    SELECT y.year, r.r_reason_desc
    FROM (
        SELECT DISTINCT d_year AS year
        FROM date_dim
        WHERE d_year BETWEEN 2000 AND 2001
    ) y
    CROSS JOIN (
        SELECT r_reason_desc
        FROM reason
        WHERE r_reason_id LIKE 'AAAA%'
    ) r
),
combined AS (
    SELECT * FROM web_profit
    UNION ALL
    SELECT * FROM store_profit
)
SELECT
    yr.year,
    yr.r_reason_desc,
    p.channel,
    p.net_profit,
    CASE
        WHEN p.net_profit > 100000 THEN 'High'
        WHEN p.net_profit > 50000  THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    (
        SELECT SUM(t.net_profit)
        FROM (
            SELECT net_profit FROM web_profit
            UNION ALL
            SELECT net_profit FROM store_profit
        ) t
    ) AS total_profit_all_channels
FROM combined p
JOIN year_reason yr ON yr.year = p.year
ORDER BY yr.year, p.channel
LIMIT 100
