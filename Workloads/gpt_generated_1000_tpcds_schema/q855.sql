WITH filtered_orders AS (
    SELECT order_num FROM (
        SELECT cr2.cr_order_number AS order_num
        FROM catalog_returns cr2
        WHERE cr2.cr_fee > 50
        INTERSECT
        SELECT cr3.cr_order_number
        FROM catalog_returns cr3
        WHERE cr3.cr_return_quantity > 1
    ) intersected
    EXCEPT
    SELECT cr4.cr_order_number
    FROM catalog_returns cr4
    WHERE cr4.cr_return_amount < 20
)
SELECT
    cp_main.cp_department,
    sm.sm_carrier,
    CASE WHEN sm.sm_carrier = 'UPS' THEN 'Preferred' ELSE 'Other' END AS carrier_category,
    COUNT(DISTINCT cr.cr_order_number) AS unique_orders,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_fee) AS avg_fee
FROM catalog_returns cr
FULL OUTER JOIN catalog_page cp_main
    ON cr.cr_catalog_page_sk = cp_main.cp_catalog_page_sk
JOIN customer cust_refunded
    ON cr.cr_refunded_customer_sk = cust_refunded.c_customer_sk
JOIN customer cust_returning
    ON cr.cr_returning_customer_sk = cust_returning.c_customer_sk
LEFT JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN ship_mode sm_alt
    ON cr.cr_ship_mode_sk = sm_alt.sm_ship_mode_sk
LEFT JOIN catalog_page cp_alt
    ON cr.cr_catalog_page_sk = cp_alt.cp_catalog_page_sk
LEFT JOIN web_page wp_refunded
    ON cust_refunded.c_customer_sk = wp_refunded.wp_customer_sk
LEFT JOIN web_page wp_returning
    ON cust_returning.c_customer_sk = wp_returning.wp_customer_sk
LEFT JOIN web_page wp_extra
    ON cust_returning.c_customer_sk = wp_extra.wp_customer_sk
WHERE cp_main.cp_type IN ('monthly', 'quarterly')
  AND cr.cr_order_number IN (SELECT order_num FROM filtered_orders)
GROUP BY
    cp_main.cp_department,
    sm.sm_carrier,
    CASE WHEN sm.sm_carrier = 'UPS' THEN 'Preferred' ELSE 'Other' END
ORDER BY total_return_amount DESC
LIMIT 100
