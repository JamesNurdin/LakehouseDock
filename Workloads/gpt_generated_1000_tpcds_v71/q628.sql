WITH base AS (
    SELECT
        c.c_customer_id,
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_sold_date_sk,
        p.p_promo_name,
        sm.sm_code,
        r.r_reason_desc,
        s.s_store_name,
        s.s_state,
        td.t_hour,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM
        catalog_returns cr
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
        JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        JOIN store_returns sr ON sr.sr_return_time_sk = td.t_time_sk
        JOIN store s ON sr.sr_store_sk = s.s_store_sk
        JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
        JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                               AND wr.wr_item_sk = ws.ws_item_sk
    WHERE
        r.r_reason_desc = 'Did not get it on time'
        AND sm.sm_code = 'AIR'
        AND p.p_discount_active = 'Y'
        AND td.t_hour BETWEEN 8 AND 12
        AND s.s_state = 'CA'
        AND c.c_birth_year BETWEEN 1950 AND 1960
)
SELECT *
FROM base
ORDER BY profit_rank, ws_net_profit DESC
LIMIT 100
