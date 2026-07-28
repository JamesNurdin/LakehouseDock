WITH joined_data AS (
    SELECT
        ss.ss_store_sk,
        st.s_store_id,
        st.s_store_name,
        st.s_state,
        ss.ss_net_profit,
        ws.ws_net_profit AS web_net_profit,
        ws.ws_order_number,
        td.t_hour,
        c.c_birth_country,
        p.p_discount_active,
        cr.cr_return_amount,
        cr.cr_refunded_cash,
        cr.cr_return_amt_inc_tax,
        cr.cr_reversed_charge,
        cr.cr_fee,
        cr.cr_return_ship_cost,
        cr.cr_net_loss,
        sm.sm_ship_mode_id,
        w.w_warehouse_id,
        ca.ca_country AS cust_country,
        cd.cd_gender,
        hd.hd_buy_potential,
        wp.wp_url
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN store st ON ss.ss_store_sk = st.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN catalog_returns cr ON cr.cr_refunded_customer_sk = c.c_customer_sk
    LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_site wsit ON ws.ws_web_site_sk = wsit.web_site_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND c.c_birth_country = 'KOREA'
      AND st.s_state = 'CA'
      AND p.p_discount_active = 'Y'
)
SELECT
    s_store_id,
    s_store_name,
    SUM(ss_net_profit) AS total_store_profit,
    SUM(web_net_profit) AS total_web_profit,
    COUNT(DISTINCT ws_order_number) AS distinct_web_orders,
    RANK() OVER (ORDER BY SUM(ss_net_profit) DESC) AS store_profit_rank
FROM joined_data
GROUP BY s_store_id, s_store_name
ORDER BY total_store_profit DESC
LIMIT 10
