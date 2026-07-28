WITH agg_sales AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        p.p_promo_id,
        SUM(ss.ss_ext_sales_price) AS store_sales_total,
        SUM(ws.ws_ext_sales_price) AS web_sales_total,
        SUM(ss.ss_ext_sales_price) + SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_txn_cnt,
        COUNT(DISTINCT ws.ws_order_number) AS web_txn_cnt
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv ON w.w_warehouse_sk = inv.inv_warehouse_sk
    JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN catalog_returns cr ON r.r_reason_sk = cr.cr_reason_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE
        s.s_state = 'CA'
        AND p.p_discount_active = 'Y'
        AND sm.sm_carrier = 'PRIVATECARRIER'
        AND w.w_state = 'CA'
        AND cr.cr_fee > 50
        AND c.c_preferred_cust_flag = 'Y'
        AND s.s_rec_end_date <= DATE '2001-01-01'
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        p.p_promo_id
)
SELECT
    s_store_id,
    s_store_name,
    p_promo_id,
    total_sales,
    store_sales_total,
    web_sales_total,
    store_txn_cnt,
    web_txn_cnt,
    ROW_NUMBER() OVER (PARTITION BY p_promo_id ORDER BY total_sales DESC) AS sales_rank
FROM agg_sales
WHERE total_sales > 100000
ORDER BY total_sales DESC
LIMIT 100
