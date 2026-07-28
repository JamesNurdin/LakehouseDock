WITH sales_join AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        ss.ss_net_paid,
        ws.ws_net_paid,
        c.c_customer_sk,
        c.c_last_name,
        c.c_birth_month,
        i.i_item_sk,
        i.i_category,
        i.i_current_price,
        p.p_promo_sk,
        p.p_discount_active,
        cc.cc_suite_number,
        w.w_state,
        s.s_state,
        wp.wp_web_page_sk,
        inv.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
       AND ss.ss_customer_sk = c.c_customer_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
       AND ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
       AND wp.wp_customer_sk = c.c_customer_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
       AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE cc.cc_suite_number = 'Suite 440'
      AND c.c_birth_month IN (11, 5)
      AND c.c_last_review_date BETWEEN 2452400 AND 2452500
      AND i.i_brand = 'BrandX'
      AND p.p_discount_active = 'Y'
      AND w.w_state = 'CA'
      AND inv.inv_quantity_on_hand > 0
      AND s.s_state = 'TX'
)
SELECT
    i_category,
    w_state,
    s_state,
    COUNT(DISTINCT c_customer_sk) AS unique_customers,
    SUM(cs_net_paid) + SUM(ss_net_paid) + SUM(ws_net_paid) AS total_net_paid,
    AVG(i_current_price) AS avg_item_price,
    MIN(inv_quantity_on_hand) AS min_inventory,
    CASE
        WHEN SUM(cs_net_paid) + SUM(ss_net_paid) + SUM(ws_net_paid) > 100000 THEN 'High'
        ELSE 'Low'
    END AS sales_category
FROM sales_join
GROUP BY i_category, w_state, s_state
ORDER BY total_net_paid DESC
LIMIT 100
