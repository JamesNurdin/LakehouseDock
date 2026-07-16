WITH active_promo_stats AS (
    SELECT
        COUNT(*) AS active_promo_count,
        AVG(p_cost) AS avg_active_promo_cost
    FROM promotion
    WHERE p_discount_active = 'Y'
),
warehouse_summary AS (
    SELECT
        w.w_warehouse_sk,
        w.w_country,
        w.w_state,
        w.w_city,
        w.w_warehouse_sq_ft,
        CASE
            WHEN w.w_warehouse_sq_ft >= 2000000 THEN 'Large'
            WHEN w.w_warehouse_sq_ft BETWEEN 1000000 AND 1999999 THEN 'Medium'
            ELSE 'Small'
        END AS size_category
    FROM warehouse w
)
SELECT
    ws.w_country,
    ws.w_state,
    ws.size_category,
    COUNT(DISTINCT i.inv_item_sk) AS distinct_items,
    SUM(i.inv_quantity_on_hand) AS total_quantity,
    AVG(i.inv_quantity_on_hand) AS avg_quantity_per_item,
    SUM(i.inv_quantity_on_hand) * COALESCE(ap.avg_active_promo_cost, 0) AS weighted_promo_cost,
    RANK() OVER (ORDER BY SUM(i.inv_quantity_on_hand) DESC) AS quantity_rank,
    (SELECT r.r_reason_desc FROM reason r WHERE r.r_reason_id = 'R001' LIMIT 1) AS sample_reason
FROM
    inventory i
JOIN
    warehouse_summary ws
    ON i.inv_warehouse_sk = ws.w_warehouse_sk
CROSS JOIN
    active_promo_stats ap
WHERE
    ws.w_state IN ('TN', 'LA', 'GA')
    AND i.inv_quantity_on_hand > 0
GROUP BY
    ws.w_country,
    ws.w_state,
    ws.size_category,
    ap.avg_active_promo_cost
HAVING
    SUM(i.inv_quantity_on_hand) > 1000
ORDER BY
    total_quantity DESC
LIMIT 20
