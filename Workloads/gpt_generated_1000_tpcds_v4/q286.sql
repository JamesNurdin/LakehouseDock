WITH base AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        ss.ss_net_profit,
        ws.ws_net_profit,
        cr.cr_return_amount,
        wr.wr_return_amt,
        cc.cc_name,
        sm.sm_type AS ship_type,
        r.r_reason_desc,
        i.inv_quantity_on_hand,
        wp.wp_url,
        ws_site.web_name AS site_name,
        d.d_date_sk
    FROM customer c
    LEFT JOIN store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    LEFT JOIN web_sales ws
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_returning_customer_sk = c.c_customer_sk
    LEFT JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN inventory i
        ON i.inv_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returning_customer_sk = c.c_customer_sk
        AND wr.wr_order_number = ws.ws_order_number
    LEFT JOIN reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
    WHERE d.d_year = 2001
      AND r.r_reason_desc = 'Wrong size'
      AND sm.sm_type = 'AIR'
      AND EXISTS (
          SELECT 1 FROM inventory i2
          WHERE i2.inv_date_sk = d.d_date_sk
            AND i2.inv_quantity_on_hand > 0
      )
),
agg AS (
    SELECT
        c_customer_id,
        c_first_name,
        c_last_name,
        d_year,
        SUM(ss_net_profit) AS total_store_profit,
        SUM(ws_net_profit) AS total_web_profit,
        SUM(ss_net_profit) + SUM(ws_net_profit) AS total_net_profit,
        SUM(cr_return_amount) AS total_catalog_return,
        SUM(wr_return_amt) AS total_web_return,
        cc_name,
        ship_type,
        r_reason_desc,
        inv_quantity_on_hand,
        wp_url,
        site_name
    FROM base
    GROUP BY
        c_customer_id,
        c_first_name,
        c_last_name,
        d_year,
        cc_name,
        ship_type,
        r_reason_desc,
        inv_quantity_on_hand,
        wp_url,
        site_name
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    d_year,
    total_store_profit,
    total_web_profit,
    total_net_profit,
    total_catalog_return,
    total_web_return,
    cc_name,
    ship_type,
    r_reason_desc,
    inv_quantity_on_hand,
    wp_url,
    site_name,
    RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM agg
ORDER BY profit_rank
LIMIT 100
