SELECT
    cp.cp_department,
    sm.sm_carrier,
    w.w_state,
    d_sold.d_year,
    COUNT(DISTINCT cs.cs_order_number) AS order_count,
    SUM(cs.cs_quantity) AS total_quantity,
    SUM(cs.cs_net_paid) AS total_net_paid,
    AVG(cs.cs_net_profit) AS avg_net_profit,
    MIN(cs.cs_net_paid) AS min_net_paid,
    MAX(cs.cs_net_paid) AS max_net_paid,
    MAX(p.p_promo_name) AS promo_name
FROM catalog_sales cs
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
WHERE
    d_sold.d_year = 2000
    AND sm.sm_carrier = 'UPS'
    AND w.w_state = 'NY'
    AND p.p_discount_active = 'Y'
    AND cp.cp_department = 'Electronics'
    AND EXISTS (
        SELECT 1
        FROM web_sales ws
        JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
        JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
        JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
        WHERE
            ws.ws_sold_date_sk = cs.cs_sold_date_sk
            AND ws.ws_warehouse_sk = cs.cs_warehouse_sk
            AND wp.wp_type = 'product'
            AND d_ws.d_year = 2000
            AND sm_ws.sm_carrier = 'UPS'
            AND w_ws.w_state = 'NY'
    )
GROUP BY
    cp.cp_department,
    sm.sm_carrier,
    w.w_state,
    d_sold.d_year
ORDER BY total_net_paid DESC
LIMIT 100
