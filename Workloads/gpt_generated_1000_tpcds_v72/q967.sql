WITH sales_per_customer AS (
    SELECT
        cust_sk,
        SUM(net_paid) AS total_spent
    FROM (
        SELECT cs.cs_bill_customer_sk AS cust_sk, cs.cs_net_paid_inc_tax AS net_paid
        FROM catalog_sales cs
        WHERE cs.cs_quantity > 0
        UNION ALL
        SELECT ss.ss_customer_sk AS cust_sk, ss.ss_net_paid_inc_tax AS net_paid
        FROM store_sales ss
        WHERE ss.ss_quantity > 0
        UNION ALL
        SELECT ws.ws_bill_customer_sk AS cust_sk, ws.ws_net_paid_inc_tax AS net_paid
        FROM web_sales ws
        WHERE ws.ws_quantity > 0
    ) q
    GROUP BY cust_sk
)
SELECT DISTINCT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    i.i_item_id,
    i.i_product_name,
    p.p_promo_name,
    s.s_store_name,
    cr.cr_return_amount,
    ws.ws_net_paid_inc_tax,
    spc.total_spent,
    DENSE_RANK() OVER (ORDER BY spc.total_spent DESC) AS spend_rank,
    COUNT(DISTINCT i.i_brand) OVER (PARTITION BY c.c_customer_sk) AS brand_count,
    td.t_hour,
    cc.cc_name,
    cp.cp_department,
    sm.sm_type,
    w.w_warehouse_name,
    ib.ib_upper_bound,
    wp.wp_url,
    we.web_name,
    r.r_reason_desc
FROM sales_per_customer spc
JOIN customer c
    ON spc.cust_sk = c.c_customer_sk
JOIN customer_address ca
    ON ca.ca_address_sk = c.c_current_addr_sk
JOIN household_demographics hd
    ON hd.hd_demo_sk = c.c_current_hdemo_sk
JOIN income_band ib
    ON ib.ib_income_band_sk = hd.hd_income_band_sk
JOIN catalog_sales cs
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN store_sales ss
    ON ss.ss_customer_sk = c.c_customer_sk
JOIN web_sales ws
    ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN item i
    ON i.i_item_sk = cs.cs_item_sk
JOIN promotion p
    ON p.p_promo_sk = cs.cs_promo_sk
JOIN store s
    ON s.s_store_sk = ss.ss_store_sk
JOIN time_dim td
    ON td.t_time_sk = cs.cs_sold_time_sk
JOIN call_center cc
    ON cc.cc_call_center_sk = cs.cs_call_center_sk
JOIN catalog_page cp
    ON cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
JOIN ship_mode sm
    ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
JOIN warehouse w
    ON w.w_warehouse_sk = cs.cs_warehouse_sk
LEFT JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_refunded_customer_sk = c.c_customer_sk
LEFT JOIN reason r
    ON r.r_reason_sk = cr.cr_reason_sk
LEFT JOIN web_page wp
    ON wp.wp_web_page_sk = ws.ws_web_page_sk
LEFT JOIN web_site we
    ON we.web_site_sk = ws.ws_web_site_sk
LEFT JOIN web_returns wr
    ON wr.wr_refunded_customer_sk = c.c_customer_sk
WHERE td.t_hour BETWEEN 9 AND 17
  AND ib.ib_upper_bound > 50000
  AND s.s_state = 'CA'
ORDER BY spend_rank, c.c_customer_id
LIMIT 100
