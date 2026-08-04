WITH max_price AS (
    SELECT MAX(i_current_price) AS max_price FROM item
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    i.i_item_id,
    i.i_product_name,
    agg.total_sales,
    agg.rnk,
    CASE WHEN i.i_current_price > (SELECT max_price FROM max_price) THEN 'Above Max' ELSE 'Below Max' END AS price_vs_max,
    wp_latest.wp_url,
    cc.cc_name,
    cr.cr_return_amount,
    wh.w_warehouse_name,
    r.r_reason_desc
FROM (
    SELECT
        ss.ss_customer_sk,
        ss.ss_item_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_customer_sk ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS rnk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i0 ON ss.ss_item_sk = i0.i_item_sk
    JOIN customer c0 ON ss.ss_customer_sk = c0.c_customer_sk
    JOIN customer_address ca0 ON ss.ss_addr_sk = ca0.ca_address_sk
    JOIN household_demographics hd0 ON ss.ss_hdemo_sk = hd0.hd_demo_sk
    JOIN income_band ib0 ON hd0.hd_income_band_sk = ib0.ib_income_band_sk
    JOIN promotion p0 ON ss.ss_promo_sk = p0.p_promo_sk
    JOIN catalog_returns cr ON d.d_date_sk = cr.cr_returned_date_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse wh ON cr.cr_warehouse_sk = wh.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_page wp0 ON wp0.wp_customer_sk = c0.c_customer_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i0.i_brand = 'Brand#12'
      AND c0.c_preferred_cust_flag = 'Y'
      AND p0.p_discount_active = 'Y'
      AND cc.cc_state = 'CA'
      AND ib0.ib_lower_bound > 50000
    GROUP BY ss.ss_customer_sk, ss.ss_item_sk
) agg
JOIN customer c ON agg.ss_customer_sk = c.c_customer_sk
JOIN item i ON agg.ss_item_sk = i.i_item_sk
JOIN catalog_returns cr ON cr.cr_returned_date_sk = (SELECT d_date_sk FROM date_dim WHERE d_year = 2001 LIMIT 1)
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN warehouse wh ON cr.cr_warehouse_sk = wh.w_warehouse_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
LEFT JOIN LATERAL (
    SELECT wp2.wp_url
    FROM web_page wp2
    WHERE wp2.wp_customer_sk = c.c_customer_sk
    ORDER BY wp2.wp_creation_date_sk DESC
    LIMIT 1
) wp_latest ON TRUE
ORDER BY agg.total_sales DESC
LIMIT 100
