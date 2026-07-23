WITH ws_agg AS (
    SELECT
        ws.ws_sold_time_sk,
        ws.ws_ship_mode_sk,
        ws.ws_promo_sk,
        ws.ws_web_page_sk,
        SUM(ws.ws_net_paid) AS sum_ws_net_paid,
        AVG(ws.ws_quantity) AS avg_ws_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS cnt_ws_orders
    FROM web_sales ws
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE td.t_hour BETWEEN 9 AND 17
    GROUP BY ws.ws_sold_time_sk, ws.ws_ship_mode_sk, ws.ws_promo_sk, ws.ws_web_page_sk
),

grouped AS (
    SELECT
        cc.cc_state,
        cc.cc_division,
        cp.cp_department,
        p.p_promo_name,
        td.t_hour,
        sm.sm_type,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(ws_agg.sum_ws_net_paid) AS total_net_paid,
        AVG(ws_agg.avg_ws_quantity) AS overall_avg_quantity,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_return_orders,
        (
            SELECT MAX(cr2.cr_return_amount)
            FROM catalog_returns cr2
            WHERE cr2.cr_call_center_sk = cc.cc_call_center_sk
        ) AS max_return_amount_for_cc
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN customer c_refunded ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
    JOIN customer_demographics cd_refunded ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    JOIN customer c_returning ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
    JOIN customer_demographics cd_returning ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
    JOIN ws_agg ON ws_agg.ws_sold_time_sk = td.t_time_sk
        AND ws_agg.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p ON ws_agg.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp ON ws_agg.ws_web_page_sk = wp.wp_web_page_sk
    WHERE cc.cc_state = 'TX'
      AND cc.cc_division = 3
      AND cd_refunded.cd_purchase_estimate > 8000
      AND wp.wp_type = 'product'
    GROUP BY
        cc.cc_state,
        cc.cc_division,
        cp.cp_department,
        p.p_promo_name,
        td.t_hour,
        sm.sm_type,
        cc.cc_call_center_sk,
        wp.wp_web_page_sk
    HAVING SUM(ws_agg.sum_ws_net_paid) > 5000
)
SELECT
    cc_state,
    cc_division,
    cp_department,
    p_promo_name,
    t_hour,
    sm_type,
    total_return_amount,
    total_net_paid,
    overall_avg_quantity,
    distinct_return_orders,
    max_return_amount_for_cc,
    ROW_NUMBER() OVER (PARTITION BY cc_state ORDER BY total_net_paid DESC) AS state_rank,
    SUM(total_net_paid) OVER (PARTITION BY cc_state) AS net_paid_by_state
FROM grouped
ORDER BY total_net_paid DESC
LIMIT 100
