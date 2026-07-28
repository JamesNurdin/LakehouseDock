WITH base_date AS (
    SELECT d.d_date_sk,
           d.d_year
    FROM tpcds.date_dim d
    WHERE d.d_year = 2001
)
SELECT
    d.d_year,
    c.c_customer_id,
    s.s_store_name,
    p.p_promo_name,
    SUM(cs.cs_net_profit)               AS catalog_net_profit,
    SUM(ss.ss_net_profit)               AS store_net_profit,
    SUM(ws.ws_net_profit)               AS web_net_profit,
    COUNT(DISTINCT cs.cs_order_number)  AS total_orders,
    (
        SELECT SUM(p2.p_cost)
        FROM tpcds.promotion p2
        WHERE p2.p_start_date_sk = d.d_date_sk
    )                                    AS promo_cost_for_day
FROM
    base_date d
    JOIN tpcds.catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.customer c
        ON c.c_customer_sk = cs.cs_bill_customer_sk
    JOIN tpcds.customer_demographics cd
        ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN tpcds.household_demographics hd
        ON hd.hd_demo_sk = c.c_current_hdemo_sk
    JOIN tpcds.income_band ib
        ON ib.ib_income_band_sk = hd.hd_income_band_sk
    JOIN tpcds.promotion p
        ON p.p_promo_sk = cs.cs_promo_sk
    JOIN tpcds.store s
        ON s.s_store_sk = ss.ss_store_sk
    JOIN tpcds.call_center cc
        ON cc.cc_call_center_sk = cs.cs_call_center_sk
    JOIN tpcds.ship_mode sm
        ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
    JOIN tpcds.warehouse w
        ON w.w_warehouse_sk = cs.cs_warehouse_sk
    JOIN tpcds.catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN tpcds.reason r
        ON r.r_reason_sk = cr.cr_reason_sk
    JOIN tpcds.inventory inv
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
        AND inv.inv_date_sk = d.d_date_sk
    JOIN tpcds.web_page wp
        ON wp.wp_web_page_sk = ws.ws_web_page_sk
    JOIN tpcds.web_site we
        ON we.web_site_sk = ws.ws_web_site_sk
WHERE
    cc.cc_manager = 'Jack Little'
    AND w.w_city = 'San Francisco'
GROUP BY
    d.d_year,
    c.c_customer_id,
    s.s_store_name,
    p.p_promo_name,
    d.d_date_sk,
    w.w_city
ORDER BY
    d.d_year DESC,
    total_orders DESC
LIMIT 100
