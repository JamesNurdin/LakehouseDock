WITH order_diff AS (
    SELECT cr.cr_order_number AS order_number
    FROM catalog_returns cr
    WHERE cr.cr_return_amount > 200
    EXCEPT
    SELECT ws.ws_order_number
    FROM web_sales ws
    WHERE ws.ws_net_paid > 1000
),
joined AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_order_number,
        dr.d_year,
        wh.w_state,
        sm.sm_type,
        r.r_reason_desc,
        p.p_discount_active,
        wp.wp_type,
        ws.ws_quantity,
        ws.ws_net_paid,
        inv.inv_quantity_on_hand
    FROM catalog_returns cr
    JOIN date_dim dr ON cr.cr_returned_date_sk = dr.d_date_sk
    JOIN time_dim tm ON cr.cr_returned_time_sk = tm.t_time_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse wh ON cr.cr_warehouse_sk = wh.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store_sales ss ON ss.ss_sold_date_sk = dr.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = dr.d_date_sk
    JOIN promotion p2 ON ws.ws_promo_sk = p2.p_promo_sk
    JOIN inventory inv ON inv.inv_date_sk = dr.d_date_sk AND inv.inv_warehouse_sk = wh.w_warehouse_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN order_diff od ON cr.cr_order_number = od.order_number
    WHERE dr.d_year = 2001
      AND wh.w_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND r.r_reason_desc = 'Customer Not Satisfied'
      AND p.p_discount_active = 'Y'
      AND wp.wp_type = 'Content'
)
SELECT
    d_year,
    w_state,
    sm_type,
    r_reason_desc,
    SUM(cr_return_amount)                         AS total_return_amount,
    AVG(ws_net_paid)                              AS avg_ws_net_paid,
    COUNT(DISTINCT cr_order_number)               AS distinct_orders,
    MIN(inv_quantity_on_hand)                     AS min_on_hand,
    MAX(ws_quantity)                              AS max_ws_quantity,
    CASE WHEN SUM(cr_net_loss) > 0 THEN 'Loss' ELSE 'Gain' END AS loss_flag,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY SUM(cr_return_amount) DESC) AS rank_year
FROM joined
GROUP BY CUBE (d_year, w_state, sm_type, r_reason_desc)
ORDER BY d_year, rank_year
LIMIT 100
