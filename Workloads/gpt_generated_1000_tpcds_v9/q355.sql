WITH store_sales_agg AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_store_sk,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS store_return_amt,
        COUNT(DISTINCT ss.ss_customer_sk) AS store_customer_cnt
    FROM store_sales ss
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    GROUP BY ss.ss_item_sk, ss.ss_store_sk
)
SELECT
    s.s_store_name,
    i.i_category,
    p.p_promo_name,
    cc.cc_name,
    sm_cs.sm_type AS ship_mode_type,
    w.w_warehouse_name,
    SUM(ssa.store_net_paid) AS total_store_net_paid,
    SUM(ssa.store_net_profit) AS total_store_net_profit,
    SUM(ssa.store_return_amt) AS total_store_return_amount,
    SUM(cs.cs_net_paid) AS total_catalog_net_paid,
    SUM(ws.ws_net_paid) AS total_web_net_paid,
    SUM(ws.ws_net_profit) AS total_web_net_profit,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
    AVG(p.p_cost) AS avg_promo_cost,
    MIN(ib.ib_lower_bound) AS min_income_lower,
    MAX(ib.ib_upper_bound) AS max_income_upper
FROM store_sales_agg ssa
JOIN store s
    ON ssa.ss_store_sk = s.s_store_sk
JOIN item i
    ON ssa.ss_item_sk = i.i_item_sk
JOIN promotion p
    ON p.p_item_sk = i.i_item_sk
JOIN catalog_sales cs
    ON cs.cs_item_sk = i.i_item_sk
JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm_cs
    ON cs.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
JOIN ship_mode sm_ws
    ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = i.i_item_sk
   AND cr.cr_call_center_sk = cc.cc_call_center_sk
   AND cr.cr_ship_mode_sk = sm_cs.sm_ship_mode_sk
   AND cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site we
    ON ws.ws_web_site_sk = we.web_site_sk
WHERE
    s.s_state = 'CA'
    AND s.s_zip = '40411'
    AND i.i_category = 'Electronics'
    AND p.p_discount_active = 'Y'
    AND cc.cc_division = 1
    AND hd.hd_vehicle_count > 1
    AND ib.ib_upper_bound <= 80000
    AND s.s_rec_end_date = DATE '2000-03-12'
    AND wp.wp_type = 'Home'
    AND we.web_country = 'United States'
    AND NOT EXISTS (
        SELECT 1 FROM catalog_returns cr2 WHERE cr2.cr_item_sk = i.i_item_sk
    )
GROUP BY
    s.s_store_name,
    i.i_category,
    p.p_promo_name,
    cc.cc_name,
    sm_cs.sm_type,
    w.w_warehouse_name
ORDER BY total_store_net_paid DESC
LIMIT 100
