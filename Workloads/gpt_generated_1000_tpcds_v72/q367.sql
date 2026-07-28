WITH sales_enriched AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_ship_customer_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_promo_sk,
        cs.cs_net_paid,
        cs.cs_ext_discount_amt,
        cs.cs_quantity
    FROM catalog_sales cs
)
SELECT
    s.s_store_name,
    ws.web_name,
    d.d_year,
    COUNT(DISTINCT se.cs_order_number) AS order_cnt,
    SUM(se.cs_net_paid) AS total_net_paid,
    AVG(se.cs_ext_discount_amt) AS avg_discount,
    MIN(se.cs_quantity) AS min_qty,
    MAX(se.cs_quantity) AS max_qty
FROM sales_enriched se
JOIN date_dim d
    ON se.cs_sold_date_sk = d.d_date_sk
JOIN customer c
    ON se.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN call_center cc
    ON se.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp
    ON se.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
    ON se.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON se.cs_warehouse_sk = w.w_warehouse_sk
JOIN promotion p
    ON se.cs_promo_sk = p.p_promo_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = se.cs_order_number
LEFT JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN web_returns wr
    ON wr.wr_refunded_customer_sk = c.c_customer_sk
JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
JOIN inventory i
    ON i.inv_warehouse_sk = w.w_warehouse_sk
    AND i.inv_date_sk = d.d_date_sk
JOIN web_site ws
    ON ws.web_close_date_sk = d.d_date_sk
WHERE
    d.d_year = 2001
    AND c.c_preferred_cust_flag = 'Y'
    AND p.p_purpose = 'Unknown'
    AND NOT EXISTS (
        SELECT 1 FROM catalog_returns cr2
        WHERE cr2.cr_refunded_customer_sk = c.c_customer_sk
    )
GROUP BY
    s.s_store_name,
    ws.web_name,
    d.d_year
ORDER BY
    total_net_paid DESC
LIMIT 100
