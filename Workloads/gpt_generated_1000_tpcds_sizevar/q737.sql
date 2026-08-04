WITH base AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_quantity,
        ss.ss_net_profit,
        d.d_year,
        s.s_store_name,
        s.s_state,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_buy_potential,
        p.p_promo_name,
        i.inv_quantity_on_hand,
        ws.ws_order_number,
        ws.ws_quantity AS ws_quantity,
        ws.ws_net_profit AS ws_net_profit,
        wp.wp_type,
        wsite.web_name,
        sm.sm_type AS ship_mode_type,
        wr.wr_net_loss
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN inventory i ON d.d_date_sk = i.inv_date_sk
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
                         AND ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND i.inv_quantity_on_hand > 0
      AND ss.ss_quantity > 1
      AND ws.ws_quantity > 0
      AND cd.cd_gender IS NOT NULL
      AND hd.hd_buy_potential = 'HIGH'
      AND wr.wr_net_loss > 0
),
union_sales AS (
    SELECT ss.ss_store_sk AS store_sk, ss.ss_net_profit AS profit
    FROM store_sales ss
    UNION
    SELECT ws.ws_web_site_sk AS store_sk, ws.ws_net_profit AS profit
    FROM web_sales ws
),
agg_union AS (
    SELECT store_sk, SUM(profit) AS total_profit
    FROM union_sales
    GROUP BY store_sk
),
full_join_cc_cr AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_order_number,
        cc.cc_name,
        cc.cc_state,
        sm.sm_type AS ship_mode_type
    FROM catalog_returns cr
    FULL OUTER JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
),
final AS (
    SELECT
        b.s_store_name,
        b.d_year,
        b.p_promo_name,
        b.inv_quantity_on_hand,
        b.ss_net_profit,
        b.ws_net_profit,
        b.cd_gender,
        b.hd_buy_potential,
        ROW_NUMBER() OVER (PARTITION BY b.s_store_name ORDER BY b.ss_net_profit DESC) AS rn,
        (SELECT SUM(ws2.ws_net_paid)
         FROM web_sales ws2
         WHERE ws2.ws_bill_customer_sk = b.ss_customer_sk) AS cust_total_web_paid,
        (SELECT MAX(d3.d_year) FROM date_dim d3) AS max_year,
        fcr.cr_return_amount,
        fcr.cc_name,
        fcr.ship_mode_type,
        au.total_profit
    FROM base b
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = b.ss_ticket_number
    LEFT JOIN full_join_cc_cr fcr ON fcr.cr_order_number = b.ws_order_number
    LEFT JOIN agg_union au ON au.store_sk = b.ss_store_sk
    WHERE b.ss_net_profit > (SELECT AVG(ss2.ss_net_profit) FROM store_sales ss2)
)
SELECT *
FROM final
WHERE rn <= 5
ORDER BY s_store_name ASC, d_year DESC
