WITH catalog_monthly AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        'Catalog' AS sales_channel,
        SUM(cs.cs_net_profit) AS total_net_profit
    FROM
        catalog_sales cs
        JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE
        d.d_year = 2020
        AND sm.sm_carrier = 'UPS'
    GROUP BY
        d.d_year,
        d.d_month_seq
),
web_monthly AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        'Web' AS sales_channel,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM
        web_sales ws
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE
        d.d_year = 2020
        AND sm.sm_carrier = 'AIRBORNE'
    GROUP BY
        d.d_year,
        d.d_month_seq
)
SELECT
    d_year,
    d_month_seq,
    sales_channel,
    total_net_profit
FROM catalog_monthly
UNION ALL
SELECT
    d_year,
    d_month_seq,
    sales_channel,
    total_net_profit
FROM web_monthly
ORDER BY d_year, d_month_seq, sales_channel
LIMIT 100
