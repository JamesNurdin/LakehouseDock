WITH cs_agg AS (
    SELECT
        sm.sm_ship_mode_id,
        sm.sm_type,
        SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        AVG(cs.cs_ext_discount_amt) AS avg_catalog_discount
    FROM catalog_sales cs
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY sm.sm_ship_mode_id, sm.sm_type
),
cr_agg AS (
    SELECT
        sm.sm_ship_mode_id,
        sm.sm_type,
        SUM(cr.cr_return_amount) AS total_returns_amount,
        SUM(cr.cr_net_loss) AS total_returns_loss,
        COUNT(*) AS return_count
    FROM catalog_returns cr
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY sm.sm_ship_mode_id, sm.sm_type
),
ws_agg AS (
    SELECT
        sm.sm_ship_mode_id,
        sm.sm_type,
        wp.wp_type,
        SUM(ws.ws_ext_sales_price) AS total_web_sales,
        SUM(ws.ws_net_profit) AS web_net_profit,
        AVG(ws.ws_ext_discount_amt) AS avg_web_discount,
        COUNT(DISTINCT ws.ws_web_page_sk) AS distinct_pages
    FROM web_sales ws
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    GROUP BY sm.sm_ship_mode_id, sm.sm_type, wp.wp_type
)
SELECT
    cs.sm_ship_mode_id,
    cs.sm_type,
    cs.total_catalog_sales,
    cs.catalog_net_profit,
    cs.avg_catalog_discount,
    cr.total_returns_amount,
    cr.total_returns_loss,
    cr.return_count,
    ws.wp_type,
    ws.total_web_sales,
    ws.web_net_profit,
    ws.avg_web_discount,
    ws.distinct_pages,
    (cs.catalog_net_profit - COALESCE(cr.total_returns_loss, 0) + COALESCE(ws.web_net_profit, 0)) AS overall_net_profit
FROM cs_agg cs
LEFT JOIN cr_agg cr
    ON cs.sm_ship_mode_id = cr.sm_ship_mode_id
   AND cs.sm_type = cr.sm_type
LEFT JOIN ws_agg ws
    ON cs.sm_ship_mode_id = ws.sm_ship_mode_id
   AND cs.sm_type = ws.sm_type
ORDER BY cs.total_catalog_sales DESC
LIMIT 10
