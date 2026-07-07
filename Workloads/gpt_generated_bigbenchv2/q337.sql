WITH item_sentiment AS (
    SELECT
        pr_item_id,
        AVG(pr_sentiment) AS avg_sentiment
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    s.s_store_name,
    i.i_category,
    SUM(ss.ss_quantity) AS total_quantity_sold,
    AVG(isent.avg_sentiment) AS avg_item_sentiment
FROM store_sales ss
JOIN customers c
    ON ss.ss_customer_id = c.c_customer_id
JOIN stores s
    ON ss.ss_store_id = s.s_store_id
JOIN items i
    ON ss.ss_item_id = i.i_item_id
LEFT JOIN item_sentiment isent
    ON ss.ss_item_id = isent.pr_item_id
GROUP BY s.s_store_name, i.i_category
ORDER BY total_quantity_sold DESC
LIMIT 10
