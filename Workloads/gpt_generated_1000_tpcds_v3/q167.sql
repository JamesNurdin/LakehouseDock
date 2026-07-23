WITH combined_sales AS (
    SELECT
        cs.cs_item_sk AS item_sk,
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_net_paid AS net_paid,
        cs.cs_promo_sk AS promo_sk,
        cs.cs_warehouse_sk AS warehouse_sk,
        cs.cs_call_center_sk AS call_center_sk,
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_quantity AS quantity,
        cs.cs_order_number AS order_number,
        NULL AS web_page_sk,
        NULL AS web_site_sk,
        'catalog' AS sales_source
    FROM catalog_sales cs
    WHERE cs.cs_net_paid > 0
    UNION ALL
    SELECT
        ws.ws_item_sk AS item_sk,
        ws.ws_sold_date_sk AS date_sk,
        ws.ws_net_paid AS net_paid,
        ws.ws_promo_sk AS promo_sk,
        ws.ws_warehouse_sk AS warehouse_sk,
        NULL AS call_center_sk,
        ws.ws_bill_customer_sk AS customer_sk,
        ws.ws_quantity AS quantity,
        ws.ws_order_number AS order_number,
        ws.ws_web_page_sk AS web_page_sk,
        ws.ws_web_site_sk AS web_site_sk,
        'web' AS sales_source
    FROM web_sales ws
    WHERE ws.ws_net_paid > 0
)
SELECT
    d.d_year,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cs.sales_source,
    cs.item_sk,
    cs.quantity,
    cs.net_paid,
    CASE
        WHEN cs.sales_source = 'catalog' THEN cs.net_paid * 0.9
        ELSE cs.net_paid * 0.95
    END AS adjusted_net_paid,
    ROW_NUMBER() OVER (PARTITION BY cs.sales_source ORDER BY cs.net_paid DESC) AS sales_rank_by_source,
    p.p_promo_name,
    w.w_warehouse_name,
    cc.cc_name,
    inv.inv_quantity_on_hand,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COALESCE(cr.cr_return_quantity, wr.wr_return_quantity) AS return_quantity,
    r.r_reason_desc,
    (SELECT COUNT(*) FROM catalog_returns cr2 WHERE cr2.cr_reason_sk = r.r_reason_sk) AS reason_return_count,
    CASE
        WHEN wp.wp_url IS NOT NULL THEN wp.wp_url
        ELSE we.web_name
    END AS source_page_or_site
FROM combined_sales cs
JOIN date_dim d
    ON cs.date_sk = d.d_date_sk
JOIN customer c
    ON cs.customer_sk = c.c_customer_sk
LEFT JOIN call_center cc
    ON cs.call_center_sk = cc.cc_call_center_sk
LEFT JOIN warehouse w
    ON cs.warehouse_sk = w.w_warehouse_sk
LEFT JOIN promotion p
    ON cs.promo_sk = p.p_promo_sk
LEFT JOIN inventory inv
    ON inv.inv_warehouse_sk = w.w_warehouse_sk
   AND inv.inv_date_sk = d.d_date_sk
LEFT JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
LEFT JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN catalog_returns cr
    ON cr.cr_item_sk = cs.item_sk
   AND cr.cr_order_number = cs.order_number
   AND cr.cr_returned_date_sk = d.d_date_sk
LEFT JOIN web_returns wr
    ON wr.wr_item_sk = cs.item_sk
   AND wr.wr_order_number = cs.order_number
   AND wr.wr_returned_date_sk = d.d_date_sk
LEFT JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
   AND sr.sr_customer_sk = c.c_customer_sk
LEFT JOIN reason r
    ON COALESCE(cr.cr_reason_sk, wr.wr_reason_sk, sr.sr_reason_sk) = r.r_reason_sk
LEFT JOIN web_page wp
    ON cs.web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_site we
    ON cs.web_site_sk = we.web_site_sk
WHERE
    d.d_year = 2001
    AND c.c_preferred_cust_flag = 'Y'
    AND ib.ib_lower_bound >= 50000
    AND p.p_discount_active = 'Y'
    AND inv.inv_quantity_on_hand > 600
ORDER BY
    cs.net_paid DESC,
    cs.sales_source,
    cs.item_sk
LIMIT 100
