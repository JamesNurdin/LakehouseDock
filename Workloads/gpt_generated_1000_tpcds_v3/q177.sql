WITH catalog_sales_union AS (
    SELECT DISTINCT
        i.i_item_id AS item_id,
        d.d_year AS sale_year,
        CASE WHEN cs.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
        'catalog' AS channel,
        sm.sm_code AS ship_mode_code
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2001
),
web_sales_union AS (
    SELECT DISTINCT
        i.i_item_id AS item_id,
        d.d_year AS sale_year,
        CASE WHEN ws.ws_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
        'web' AS channel,
        sm.sm_code AS ship_mode_code
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2001
),
combined_sales AS (
    SELECT * FROM catalog_sales_union
    UNION ALL
    SELECT * FROM web_sales_union
)
SELECT
    cs.item_id,
    cs.sale_year,
    cs.profit_flag,
    cs.channel,
    COUNT(*) AS transaction_count,
    COUNT(DISTINCT cs.ship_mode_code) AS distinct_ship_modes
FROM combined_sales cs
GROUP BY
    cs.item_id,
    cs.sale_year,
    cs.profit_flag,
    cs.channel
ORDER BY transaction_count DESC
LIMIT 100
