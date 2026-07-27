SELECT
    cp.cp_department,
    i.i_brand,
    w.w_state,
    cd_refunded.cd_gender,
    CASE
        WHEN p.p_purpose = 'Unknown' THEN 'Other'
        ELSE p.p_purpose
    END AS promo_purpose_category,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_quantity) AS avg_return_quantity,
    COUNT(DISTINCT cr.cr_order_number) AS distinct_orders,
    MIN(cr.cr_return_amount) AS min_return_amount,
    MAX(cr.cr_return_amount) AS max_return_amount
FROM
    catalog_returns cr
JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN promotion p
    ON p.p_item_sk = i.i_item_sk
JOIN customer c_refunded
    ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN customer_demographics cd_refunded
    ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
JOIN household_demographics hd_refunded
    ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN income_band ib
    ON hd_refunded.hd_income_band_sk = ib.ib_income_band_sk
WHERE
    cp.cp_department = 'Electronics'
    AND i.i_current_price BETWEEN 100 AND 500
    AND w.w_state = 'CA'
    AND r.r_reason_desc = 'Customer not satisfied'
    AND p.p_discount_active = 'Y'
    AND cd_refunded.cd_gender = 'M'
    AND EXISTS (
        SELECT 1
        FROM web_returns wr
        JOIN web_page wp
            ON wr.wr_web_page_sk = wp.wp_web_page_sk
        WHERE
            wr.wr_item_sk = cr.cr_item_sk
            AND wp.wp_type = 'product'
            AND wp.wp_max_ad_count >= 2
    )
GROUP BY
    cp.cp_department,
    i.i_brand,
    w.w_state,
    cd_refunded.cd_gender,
    CASE
        WHEN p.p_purpose = 'Unknown' THEN 'Other'
        ELSE p.p_purpose
    END
ORDER BY total_return_amount DESC
LIMIT 100
