WITH base AS (
    SELECT
        cp.cp_department,
        w.w_state,
        i.i_color,
        CASE WHEN i.i_color = 'Red' THEN 'Red' ELSE 'Other' END AS color_group,
        ss.ss_net_paid AS store_net_paid,
        ws.ws_net_paid AS web_net_paid,
        ss.ss_ext_discount_amt AS store_discount,
        ws.ws_ext_discount_amt AS web_discount,
        ss.ss_quantity AS store_qty,
        ws.ws_quantity AS web_qty,
        cr.cr_return_amount,
        p.p_discount_active
    FROM catalog_page cp
    JOIN catalog_returns cr
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN promotion p
        ON p.p_item_sk = i.i_item_sk
    JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
        AND ss.ss_promo_sk = p.p_promo_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_warehouse_sk = w.w_warehouse_sk
        AND ws.ws_promo_sk = p.p_promo_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE cp.cp_department = 'Electronics'
      AND w.w_state = 'MN'
      AND i.i_brand = 'Brand#12'
      AND wp.wp_max_ad_count >= 2
      AND ss.ss_sold_date_sk BETWEEN 2450000 AND 2450100
)
SELECT
    cp_department,
    w_state,
    color_group,
    COUNT(*) AS txn_count,
    SUM(store_net_paid) AS total_store_sales,
    SUM(web_net_paid) AS total_web_sales,
    SUM(store_net_paid + web_net_paid) AS total_combined_sales,
    AVG(store_discount + web_discount) AS avg_total_discount,
    MIN(cr_return_amount) AS min_return_amount,
    MAX(cr_return_amount) AS max_return_amount,
    SUM(CASE WHEN p_discount_active = 'Y' THEN 1 ELSE 0 END) AS active_promo_count
FROM base
GROUP BY cp_department, w_state, color_group
ORDER BY total_combined_sales DESC
LIMIT 100
