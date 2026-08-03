WITH joined_data AS (
    SELECT
        t.t_hour,
        p.p_promo_name,
        sm.sm_ship_mode_id,
        w.w_warehouse_name,
        w.w_state,
        ss.ss_net_profit AS store_net_profit,
        ws.ws_net_profit AS web_net_profit,
        ws.ws_coupon_amt,
        CASE WHEN ws.ws_coupon_amt > 2000 THEN 'High' ELSE 'Low' END AS coupon_level
    FROM time_dim t
    JOIN store_sales ss
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store_returns sr
        ON sr.sr_return_time_sk = t.t_time_sk
        AND sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN catalog_returns cr
        ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws
        ON ws.ws_sold_time_sk = t.t_time_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        AND ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE t.t_hour BETWEEN 8 AND 12
      AND p.p_discount_active = 'y'
      AND sm.sm_contract LIKE 'ldhM8I%'
      AND w.w_state = 'CA'
      AND ws.ws_coupon_amt > 1000
),
aggregated AS (
    SELECT
        w_warehouse_name,
        t_hour,
        sm_ship_mode_id,
        coupon_level,
        SUM(store_net_profit + web_net_profit) AS total_profit
    FROM joined_data
    GROUP BY w_warehouse_name, t_hour, sm_ship_mode_id, coupon_level
)
SELECT
    w_warehouse_name,
    t_hour,
    sm_ship_mode_id,
    coupon_level,
    total_profit,
    RANK() OVER (PARTITION BY w_warehouse_name ORDER BY total_profit DESC) AS profit_rank
FROM aggregated
ORDER BY total_profit DESC
LIMIT 100
