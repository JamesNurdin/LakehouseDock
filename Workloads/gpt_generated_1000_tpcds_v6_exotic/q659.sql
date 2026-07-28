WITH max_promo AS (
        SELECT max(p_cost) AS max_cost
        FROM promotion
    ),
    agg AS (
        SELECT
            cc.cc_state,
            td_cr.t_hour,
            r.r_reason_desc,
            SUM(ss.ss_net_profit) AS total_store_profit,
            SUM(ws.ws_net_profit) AS total_web_profit,
            COUNT(DISTINCT c_refunded.c_customer_id) AS unique_customers,
            SUM(ws.ws_ext_wholesale_cost) AS total_wholesale_cost
        FROM catalog_returns cr
        JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        JOIN time_dim td_cr ON cr.cr_returned_time_sk = td_cr.t_time_sk
        JOIN customer c_refunded ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
        JOIN customer_demographics cd_refunded ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
        JOIN household_demographics hd_refunded ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
        /* join store_sales via the same time dimension (allowed by join rule) */
        JOIN store_sales ss ON ss.ss_sold_time_sk = td_cr.t_time_sk
        JOIN time_dim td_ss ON ss.ss_sold_time_sk = td_ss.t_time_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        /* join web_sales via the same time dimension */
        JOIN web_sales ws ON ws.ws_sold_time_sk = td_cr.t_time_sk
        JOIN time_dim td_ws ON ws.ws_sold_time_sk = td_ws.t_time_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        JOIN time_dim td_wr ON wr.wr_returned_time_sk = td_wr.t_time_sk
        JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
        WHERE
            cc.cc_state = 'CA'
            AND c_refunded.c_birth_country = 'JAPAN'
            AND cp.cp_type = 'FULL'
            AND sm.sm_type = 'AIR'
            AND td_cr.t_hour BETWEEN 9 AND 17
            AND ss.ss_quantity > 5
            AND cr.cr_return_amount > 1000
        GROUP BY
            GROUPING SETS (
                (cc.cc_state, td_cr.t_hour, r.r_reason_desc),
                (cc.cc_state, td_cr.t_hour),
                (cc.cc_state)
            )
    )
SELECT
    cc_state,
    t_hour,
    r_reason_desc,
    total_store_profit,
    total_web_profit,
    unique_customers,
    ROW_NUMBER() OVER (PARTITION BY cc_state ORDER BY (total_store_profit + total_web_profit) DESC) AS profit_rank,
    CASE WHEN total_wholesale_cost > (SELECT max_cost FROM max_promo) THEN 'HIGH_COST' ELSE 'NORMAL' END AS cost_category,
    (SELECT COUNT(DISTINCT p2.p_promo_id) FROM promotion p2 WHERE p2.p_discount_active = 'Y') AS active_promo_cnt
FROM agg
ORDER BY profit_rank, total_store_profit DESC
LIMIT 100
