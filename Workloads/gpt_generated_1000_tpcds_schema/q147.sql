WITH cs_sample AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
),
joined AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_net_paid,
        cs.cs_ext_tax,
        i.i_item_sk,
        i.i_category,
        i.i_product_name,
        p.p_promo_id,
        p.p_channel_demo,
        cp.cp_catalog_page_number,
        cc.cc_call_center_id,
        sm.sm_type AS ship_mode_type,
        w.w_warehouse_id,
        cust.c_customer_id,
        ca.ca_state AS cust_state,
        s.s_store_id,
        s.s_state AS store_state,
        ws.ws_net_paid AS ws_net_paid,
        ws.ws_ext_tax AS ws_ext_tax,
        cr.cr_return_quantity,
        cr.cr_return_amount,
        wp.wp_url,
        ROW_NUMBER() OVER (ORDER BY cs.cs_sold_date_sk) AS global_row_num
    FROM cs_sample cs
    JOIN catalog_page cp               ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc                ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm                  ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w                   ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i                        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p                   ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer cust                 ON cs.cs_bill_customer_sk = cust.c_customer_sk
    JOIN customer_address ca           ON cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN catalog_returns cr      ON cr.cr_order_number = cs.cs_order_number
                                      AND cr.cr_item_sk = i.i_item_sk
    LEFT JOIN web_sales ws            ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_page wp              ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN store_sales ss           ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store s                  ON ss.ss_store_sk = s.s_store_sk
)
SELECT
    p.p_promo_id,
    i.i_category,
    s.s_state AS store_state,
    COUNT(DISTINCT joined.cs_order_number) AS order_cnt,
    SUM(joined.cs_net_paid) AS total_net_paid,
    AVG(joined.ws_net_paid) AS avg_ws_net_paid,
    MIN(joined.cs_ext_tax) AS min_ext_tax,
    MAX(joined.cs_ext_tax) AS max_ext_tax,
    SUM(joined.cr_return_amount) AS total_return_amount,
    COUNT(*) AS total_rows,
    MAX(global_row_num) AS max_row_num
FROM joined
JOIN promotion p ON joined.p_promo_id = p.p_promo_id
JOIN item i ON joined.i_item_sk = i.i_item_sk
JOIN store s ON joined.s_store_id = s.s_store_id
WHERE p.p_channel_demo = 'N'
  AND joined.cp_catalog_page_number = 10
  AND s.s_state = 'CA'
GROUP BY p.p_promo_id, i.i_category, s.s_state
ORDER BY total_net_paid DESC
LIMIT 100
