WITH ws_agg AS (
    SELECT
        ws_item_sk,
        ws_order_number,
        SUM(ws_net_paid) AS total_net_paid,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt
    FROM web_sales
    WHERE ws_quantity > 1
    GROUP BY ws_item_sk, ws_order_number
)
SELECT
    ss.ss_ticket_number,
    ss.ss_net_profit,
    cr.cr_return_amount,
    sm_cr.sm_ship_mode_id,
    w_cr.w_warehouse_name,
    p_ss.p_promo_name,
    t1.t_hour,
    ws.ws_order_number,
    wa.total_net_paid,
    wa.total_net_profit,
    site.web_name,
    RANK() OVER (PARTITION BY t1.t_hour ORDER BY wa.total_net_profit DESC) AS profit_rank_hour,
    CASE
        WHEN p_ws.p_cost > (
            SELECT AVG(p_cost)
            FROM promotion
            WHERE p_discount_active = 'Y'
        ) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS promo_cost_category
FROM store_sales ss
JOIN time_dim t1 ON ss.ss_sold_time_sk = t1.t_time_sk
JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
JOIN promotion p_ss ON ss.ss_promo_sk = p_ss.p_promo_sk
JOIN catalog_returns cr ON cr.cr_returned_time_sk = t1.t_time_sk
JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
JOIN warehouse w_cr ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
JOIN customer_address ca_cr_refund ON cr.cr_refunded_addr_sk = ca_cr_refund.ca_address_sk
JOIN web_sales ws ON ws.ws_sold_time_sk = t1.t_time_sk
JOIN ws_agg wa ON wa.ws_item_sk = ws.ws_item_sk AND wa.ws_order_number = ws.ws_order_number
JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN warehouse w_ws ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
JOIN customer_address ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
JOIN customer_address ca_ws_ship ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
JOIN web_returns wr ON wr.wr_item_sk = ws.ws_item_sk AND wr.wr_order_number = ws.ws_order_number
JOIN time_dim t3 ON wr.wr_returned_time_sk = t3.t_time_sk
JOIN customer_address ca_wr_refund ON wr.wr_refunded_addr_sk = ca_wr_refund.ca_address_sk
JOIN customer_address ca_wr_returning ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk
WHERE
    t1.t_hour BETWEEN 9 AND 17
    AND sm_cr.sm_code = 'AIR'
    AND p_ss.p_cost BETWEEN 500 AND 5000
    AND w_cr.w_state = 'CA'
    AND site.web_company_name = 'able'
    AND ca_ss.ca_state = 'TX'
ORDER BY profit_rank_hour ASC, ss.ss_net_profit DESC
LIMIT 100
