WITH sampled_inventory AS (
    SELECT inv_item_sk, inv_quantity_on_hand
    FROM inventory
    TABLESAMPLE BERNOULLI (10)
),
order_intersect AS (
    SELECT cr_order_number
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk = 2452
    INTERSECT
    SELECT cr2.cr_order_number
    FROM catalog_returns cr2
    WHERE cr2.cr_return_amount > 100
),
order_except AS (
    SELECT cr_order_number
    FROM catalog_returns cr
    WHERE cr.cr_returned_date_sk = 2452
    EXCEPT
    SELECT cr3.cr_order_number
    FROM catalog_returns cr3
    WHERE cr3.cr_return_amount > 100
)
SELECT
    d.d_year,
    s.s_state,
    p.p_channel_tv,
    COUNT(DISTINCT cr.cr_order_number) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(si.inv_quantity_on_hand) AS avg_inventory_on_hand,
    MIN(cr.cr_return_amount) AS min_return_amount,
    MAX(cr.cr_return_amount) AS max_return_amount
FROM date_dim d
JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
JOIN catalog_page cp ON cp.cp_catalog_page_sk = cr.cr_catalog_page_sk
JOIN customer c ON c.c_customer_sk = cr.cr_refunded_customer_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
LEFT JOIN sampled_inventory si ON si.inv_item_sk = cr.cr_item_sk
WHERE
    d.d_year = 2001
    AND s.s_floor_space > 8000000
    AND s.s_county = 'Mesa County'
    AND cp.cp_type = 'monthly'
    AND ws.web_state = 'CA'
    AND EXISTS (
        SELECT 1
        FROM promotion p2
        WHERE p2.p_promo_sk = cr.cr_reason_sk
          AND p2.p_discount_active = 'Y'
    )
    AND cr.cr_catalog_page_sk IN (
        SELECT cp2.cp_catalog_page_sk
        FROM catalog_page cp2
        WHERE cp2.cp_type = 'monthly'
    )
    AND cr.cr_order_number IN (SELECT cr_order_number FROM order_intersect)
    AND cr.cr_order_number NOT IN (SELECT cr_order_number FROM order_except)
GROUP BY
    d.d_year,
    s.s_state,
    p.p_channel_tv
ORDER BY
    total_return_amount DESC,
    num_returns DESC
LIMIT 100
