WITH male_customer_stats AS (
    SELECT 
        COUNT(*) AS male_cnt,
        (SELECT COUNT(*) FROM customer) AS total_cnt
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'M'
)
SELECT
    w.w_warehouse_id,
    w.w_city,
    w.w_state,
    SUM(i.inv_quantity_on_hand) AS total_qty,
    COUNT(DISTINCT i.inv_item_sk) AS distinct_items,
    CASE 
        WHEN SUM(i.inv_quantity_on_hand) >= 1000000 THEN 'Large'
        WHEN SUM(i.inv_quantity_on_hand) >= 500000 THEN 'Medium'
        ELSE 'Small'
    END AS warehouse_size_category,
    ROW_NUMBER() OVER (PARTITION BY w.w_state ORDER BY SUM(i.inv_quantity_on_hand) DESC) AS rank_by_state,
    (SELECT male_cnt * 1.0 / total_cnt FROM male_customer_stats) AS male_customer_ratio
FROM inventory i
JOIN warehouse w
    ON i.inv_warehouse_sk = w.w_warehouse_sk
WHERE w.w_country = 'United States'
GROUP BY w.w_warehouse_id, w.w_city, w.w_state
HAVING SUM(i.inv_quantity_on_hand) > 0
ORDER BY total_qty DESC
LIMIT 10
