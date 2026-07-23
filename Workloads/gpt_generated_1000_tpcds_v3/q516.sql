SELECT
    it.i_brand,
    it.i_category,
    CASE 
        WHEN it.i_current_price < 10 THEN 'Low'
        WHEN it.i_current_price < 50 THEN 'Medium'
        ELSE 'High'
    END AS price_tier,
    COUNT(DISTINCT it.i_item_id) AS distinct_item_count,
    SUM(i.inv_quantity_on_hand) AS total_quantity_on_hand,
    AVG(it.i_wholesale_cost) AS avg_wholesale_cost,
    MIN(i.inv_quantity_on_hand) AS min_quantity_on_hand,
    MAX(i.inv_quantity_on_hand) AS max_quantity_on_hand,
    SUM(CASE WHEN i.inv_quantity_on_hand > 800 THEN i.inv_quantity_on_hand ELSE 0 END) AS high_quantity_sum
FROM inventory i
JOIN item it
    ON i.inv_item_sk = it.i_item_sk
WHERE
    it.i_wholesale_cost > 1.00
    AND it.i_rec_start_date >= DATE '2000-01-01'
    AND it.i_formulation LIKE '%goldenrod%'
    AND i.inv_quantity_on_hand >= 500
    AND EXISTS (
        SELECT 1
        FROM warehouse w
        WHERE w.w_warehouse_sk = i.inv_warehouse_sk
            AND w.w_suite_number = 'Suite 160'
            AND w.w_city = 'Seattle'
    )
GROUP BY
    it.i_brand,
    it.i_category,
    CASE 
        WHEN it.i_current_price < 10 THEN 'Low'
        WHEN it.i_current_price < 50 THEN 'Medium'
        ELSE 'High'
    END
ORDER BY total_quantity_on_hand DESC
LIMIT 100
