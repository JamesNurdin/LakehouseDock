WITH returns_agg AS (
    SELECT
        cr.cr_warehouse_sk AS cr_warehouse_sk,
        cr.cr_ship_mode_sk AS cr_ship_mode_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE
        sm.sm_code = 'AIR'
        AND td.t_second = 7
        AND w.w_state = 'CA'
        AND cc.cc_country = 'United States'
    GROUP BY cr.cr_warehouse_sk, cr.cr_ship_mode_sk
)
SELECT
    w.w_warehouse_name,
    sm.sm_code,
    ra.total_return_amount,
    ra.return_cnt,
    SUM(ws.ws_net_paid) AS total_sales,
    COUNT(DISTINCT ws.ws_order_number) AS sales_orders,
    AVG(ws.ws_net_paid) AS avg_sale,
    CASE WHEN SUM(ws.ws_net_paid) > 100000 THEN 'HIGH' ELSE 'LOW' END AS sales_category,
    MIN(ws.ws_sold_date_sk) AS earliest_sale_sk,
    MAX(ws.ws_sold_date_sk) AS latest_sale_sk,
    (
        SELECT COUNT(*)
        FROM catalog_returns cr2
        WHERE cr2.cr_warehouse_sk = w.w_warehouse_sk
    ) AS total_returns_in_warehouse
FROM returns_agg ra
JOIN web_sales ws ON ws.ws_warehouse_sk = ra.cr_warehouse_sk
    AND ws.ws_ship_mode_sk = ra.cr_ship_mode_sk
JOIN ship_mode sm ON sm.sm_ship_mode_sk = ra.cr_ship_mode_sk
JOIN warehouse w ON w.w_warehouse_sk = ra.cr_warehouse_sk
JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN time_dim td_ws ON ws.ws_sold_time_sk = td_ws.t_time_sk
WHERE
    ws.ws_quantity > 5
    AND ws.ws_net_paid > 0
    AND wp.wp_type = 'Content'
    AND wp.wp_max_ad_count >= 2
    AND inv.inv_quantity_on_hand > 200
    AND td_ws.t_hour = 10
GROUP BY
    w.w_warehouse_name,
    sm.sm_code,
    ra.total_return_amount,
    ra.return_cnt,
    w.w_warehouse_sk,
    sm.sm_ship_mode_sk
ORDER BY total_sales DESC
LIMIT 100
