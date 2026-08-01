WITH dhl_sales AS (
    SELECT
        sm.sm_carrier AS carrier,
        d.d_year AS year,
        SUM(ws_distinct.ws_net_profit) AS total_profit
    FROM (
        SELECT DISTINCT
            ws_order_number,
            ws_net_profit,
            ws_ship_mode_sk,
            ws_sold_date_sk
        FROM web_sales
    ) ws_distinct
    JOIN ship_mode sm ON ws_distinct.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN date_dim d ON ws_distinct.ws_sold_date_sk = d.d_date_sk
    WHERE sm.sm_carrier = 'DHL'
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY sm.sm_carrier, d.d_year
),

diamond_sales AS (
    SELECT
        sm.sm_carrier AS carrier,
        d.d_year AS year,
        SUM(ws_distinct.ws_net_profit) AS total_profit
    FROM (
        SELECT DISTINCT
            ws_order_number,
            ws_net_profit,
            ws_ship_mode_sk,
            ws_sold_date_sk
        FROM web_sales
    ) ws_distinct
    JOIN ship_mode sm ON ws_distinct.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN date_dim d ON ws_distinct.ws_sold_date_sk = d.d_date_sk
    WHERE sm.sm_carrier = 'DIAMOND'
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY sm.sm_carrier, d.d_year
)
SELECT
    carrier,
    year,
    total_profit,
    CASE WHEN total_profit > 1000000 THEN 'High' ELSE 'Low' END AS profit_category
FROM (
    SELECT carrier, year, total_profit FROM dhl_sales
    UNION ALL
    SELECT carrier, year, total_profit FROM diamond_sales
) final
ORDER BY carrier, year
LIMIT 100
