WITH first_part AS (
    SELECT
        i.i_category AS category,
        i.i_brand AS brand,
        w.w_state AS state,
        sm.sm_type AS ship_type,
        ws.ws_ext_sales_price AS sales_price,
        cr.cr_return_amount AS return_amount,
        ws.ws_order_number AS order_number,
        (SELECT COUNT(*) FROM promotion p_sub WHERE p_sub.p_item_sk = i.i_item_sk) AS promo_cnt
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk AND cr.cr_warehouse_sk = w.w_warehouse_sk AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE i.i_rec_start_date > DATE '2000-01-01'
      AND wp.wp_char_count > 5000
      AND cc.cc_state = 'CA'
      AND cp.cp_catalog_page_id LIKE 'AAAA%'
),
second_part AS (
    SELECT
        i.i_category AS category,
        i.i_brand AS brand,
        w.w_state AS state,
        sm.sm_type AS ship_type,
        ws.ws_ext_sales_price AS sales_price,
        cr.cr_return_amount AS return_amount,
        ws.ws_order_number AS order_number,
        (SELECT COUNT(*) FROM promotion p_sub WHERE p_sub.p_item_sk = i.i_item_sk) AS promo_cnt
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c_bill ON ws.ws_bill_customer_sk = c_bill.c_customer_sk
    JOIN customer_demographics cd_bill ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk AND cr.cr_warehouse_sk = w.w_warehouse_sk AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    WHERE i.i_category = 'Electronics'
      AND wp.wp_char_count BETWEEN 3000 AND 6000
      AND p.p_discount_active = 'Y'
      AND cc.cc_country = 'UNITED STATES'
)
SELECT
    category,
    brand,
    state,
    ship_type,
    SUM(sales_price) AS total_sales,
    SUM(return_amount) AS total_returns,
    COUNT(DISTINCT order_number) AS distinct_orders,
    AVG(promo_cnt) AS avg_promo_count
FROM first_part
GROUP BY category, brand, state, ship_type
HAVING SUM(sales_price) > 10000
UNION
SELECT
    category,
    brand,
    state,
    ship_type,
    SUM(sales_price) AS total_sales,
    SUM(return_amount) AS total_returns,
    COUNT(DISTINCT order_number) AS distinct_orders,
    AVG(promo_cnt) AS avg_promo_count
FROM second_part
GROUP BY category, brand, state, ship_type
HAVING SUM(sales_price) > 5000
ORDER BY total_sales DESC
LIMIT 100
