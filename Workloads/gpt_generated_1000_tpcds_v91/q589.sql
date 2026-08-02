WITH base AS (
    SELECT
        s.s_store_name,
        s.s_state,
        r_cr.r_reason_desc,
        td.t_hour,
        SUM(cr.cr_return_amount) AS total_cr_return_amount,
        SUM(sr.sr_net_loss) AS total_sr_net_loss,
        SUM(ws.ws_net_paid) AS total_ws_net_paid,
        AVG(ws.ws_ext_ship_cost) AS avg_ws_ext_ship_cost,
        MAX(cr.cr_return_quantity) AS max_cr_return_quantity,
        SUM(CASE WHEN sm_ws.sm_type = 'AIR' THEN ws.ws_net_paid ELSE 0 END) AS air_shipping_sales,
        (SELECT AVG(p2.p_cost) FROM promotion p2 WHERE p2.p_discount_active = 'Y') AS avg_active_promo_cost
    FROM catalog_returns cr
    JOIN time_dim td
        ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN customer c_ref
        ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
    JOIN household_demographics hd_ref
        ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN income_band ib
        ON hd_ref.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca_ref
        ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN reason r_cr
        ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN store_returns sr
        ON sr.sr_return_time_sk = td.t_time_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN customer c_sr
        ON sr.sr_customer_sk = c_sr.c_customer_sk
    JOIN household_demographics hd_sr
        ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
    JOIN customer_address ca_sr
        ON sr.sr_addr_sk = ca_sr.ca_address_sk
    JOIN reason r_sr
        ON sr.sr_reason_sk = r_sr.r_reason_sk
    JOIN web_sales ws
        ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN customer c_ws_bill
        ON ws.ws_bill_customer_sk = c_ws_bill.c_customer_sk
    JOIN household_demographics hd_ws_bill
        ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
    JOIN customer_address ca_ws_bill
        ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
    JOIN customer c_ws_ship
        ON ws.ws_ship_customer_sk = c_ws_ship.c_customer_sk
    JOIN household_demographics hd_ws_ship
        ON ws.ws_ship_hdemo_sk = hd_ws_ship.hd_demo_sk
    JOIN customer_address ca_ws_ship
        ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN ship_mode sm_ws
        ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE
        cr.cr_return_quantity = 2
        AND cr.cr_return_amount > 1000.00
        AND ws.ws_ext_ship_cost > 500.00
        AND ws.ws_list_price BETWEEN 50.00 AND 200.00
        AND ca_ref.ca_zip = '75124'
        AND ca_ref.ca_suite_number = 'Suite O'
        AND s.s_state = 'CA'
        AND sm.sm_type = 'AIR'
        AND ws.ws_net_paid_inc_tax > 1000.00
        AND p.p_discount_active = 'Y'
        AND EXISTS (
            SELECT 1
            FROM web_page wp
            WHERE wp.wp_web_page_sk = ws.ws_web_page_sk
              AND wp.wp_autogen_flag = 'N'
        )
    GROUP BY ROLLUP (s.s_store_name, s.s_state, r_cr.r_reason_desc, td.t_hour)
)
SELECT
    base.s_store_name,
    base.s_state,
    base.r_reason_desc,
    base.t_hour,
    base.total_cr_return_amount,
    base.total_sr_net_loss,
    base.total_ws_net_paid,
    base.avg_ws_ext_ship_cost,
    base.max_cr_return_quantity,
    base.air_shipping_sales,
    base.avg_active_promo_cost,
    ROW_NUMBER() OVER (ORDER BY base.total_ws_net_paid DESC) AS rn
FROM base
ORDER BY rn
LIMIT 100
