WITH ss_agg AS (
    SELECT
        ss_store_sk,
        ss_sold_date_sk,
        ss_promo_sk,
        SUM(ss_net_paid) AS store_net_paid,
        SUM(ss_net_profit) AS store_net_profit,
        COUNT(*) AS store_sales_cnt
    FROM store_sales
    GROUP BY ss_store_sk, ss_sold_date_sk, ss_promo_sk
)
SELECT
    s.s_store_name,
    d_store.d_year,
    p.p_promo_name,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    SUM(ss_agg.store_net_paid) AS total_store_net_paid,
    SUM(cs.cs_net_paid) AS total_catalog_net_paid,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    SUM(CASE WHEN cc.cc_division = 1 THEN cs.cs_net_paid ELSE 0 END) AS division1_catalog_sales,
    AVG(ss_agg.store_net_profit) AS avg_store_profit,
    MIN(d_store.d_date) AS first_sale_date,
    MAX(d_store.d_date) AS last_sale_date
FROM ss_agg
JOIN store s
    ON ss_agg.ss_store_sk = s.s_store_sk
JOIN date_dim d_store
    ON ss_agg.ss_sold_date_sk = d_store.d_date_sk
JOIN promotion p
    ON ss_agg.ss_promo_sk = p.p_promo_sk
JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = d_store.d_date_sk
    AND cs.cs_promo_sk = p.p_promo_sk
JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
    AND cr.cr_item_sk = cs.cs_item_sk
JOIN date_dim d_return
    ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN time_dim t_return
    ON cr.cr_returned_time_sk = t_return.t_time_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d_store.d_date_sk
JOIN time_dim t_web
    ON wr.wr_returned_time_sk = t_web.t_time_sk
JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
WHERE
    d_store.d_year = 2001
    AND s.s_state = 'CA'
    AND p.p_discount_active = 'Y'
GROUP BY
    s.s_store_name,
    d_store.d_year,
    p.p_promo_name
ORDER BY
    total_store_net_paid DESC
LIMIT 100
