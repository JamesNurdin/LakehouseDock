WITH sales_agg AS (
    SELECT
        cs_order_number,
        cs_item_sk,
        cs_sold_date_sk,
        cs_call_center_sk,
        cs_warehouse_sk,
        cs_ship_mode_sk,
        cs_catalog_page_sk,
        cs_promo_sk,
        SUM(cs_net_paid) AS sum_net_paid,
        SUM(cs_quantity) AS sum_quantity,
        COUNT(*) AS cnt_sales
    FROM catalog_sales
    WHERE cs_sold_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2020
    )
    GROUP BY cs_order_number, cs_item_sk, cs_sold_date_sk, cs_call_center_sk,
             cs_warehouse_sk, cs_ship_mode_sk, cs_catalog_page_sk, cs_promo_sk
)
SELECT
    d.d_year,
    i.i_category,
    cc.cc_name,
    sm.sm_type,
    w.w_city,
    r.r_reason_desc,
    SUM(sa.sum_net_paid) AS total_net_paid,
    SUM(sa.sum_quantity) AS total_quantity,
    COUNT(DISTINCT sa.cs_order_number) AS distinct_orders,
    AVG(sa.sum_net_paid) AS avg_order_value
FROM sales_agg sa
JOIN date_dim d ON sa.cs_sold_date_sk = d.d_date_sk
JOIN item i ON sa.cs_item_sk = i.i_item_sk
JOIN call_center cc ON sa.cs_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w ON sa.cs_warehouse_sk = w.w_warehouse_sk
JOIN ship_mode sm ON sa.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN catalog_page cp ON sa.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p ON sa.cs_promo_sk = p.p_promo_sk
LEFT JOIN catalog_returns cr ON sa.cs_order_number = cr.cr_order_number
JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    AND sr.sr_returned_date_sk = d.d_date_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
WHERE
    cc.cc_state = 'CA'
    AND w.w_city = 'Oak'
    AND i.i_brand = 'BrandX'
    AND p.p_discount_active = 'Y'
    AND r.r_reason_desc = 'Did not like the warranty'
    AND sa.cs_order_number NOT IN (
        SELECT cr2.cr_order_number
        FROM catalog_returns cr2
    )
GROUP BY d.d_year, i.i_category, cc.cc_name, sm.sm_type, w.w_city, r.r_reason_desc
ORDER BY total_net_paid DESC
LIMIT 100
