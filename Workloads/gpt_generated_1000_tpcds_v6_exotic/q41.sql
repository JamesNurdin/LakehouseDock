WITH combined AS (
    SELECT
        i.i_item_id AS item_id,
        CAST(NULL AS VARCHAR) AS ship_mode_id,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        CASE WHEN SUM(ss.ss_net_profit) > 1000 THEN 'High' ELSE 'Low' END AS profit_bucket,
        ROW_NUMBER() OVER (ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS sales_rank
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE i.i_category_id = 5
    GROUP BY i.i_item_id

    UNION ALL

    SELECT
        i.i_item_id AS item_id,
        sm.sm_ship_mode_id AS ship_mode_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        CASE WHEN SUM(ws.ws_net_profit) > 500 THEN 'High' ELSE 'Low' END AS profit_bucket,
        ROW_NUMBER() OVER (ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE i.i_brand = 'exportiimporto #1'
    GROUP BY i.i_item_id, sm.sm_ship_mode_id
)
SELECT
    item_id,
    ship_mode_id,
    total_sales,
    total_profit,
    sales_cnt,
    profit_bucket,
    sales_rank
FROM combined
ORDER BY total_sales DESC
LIMIT 100
