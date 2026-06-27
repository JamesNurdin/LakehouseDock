WITH item_ratings AS (
    SELECT
        pr_item_id,
        avg(pr_rating) AS avg_rating
    FROM product_reviews
    GROUP BY pr_item_id
),
store_sales_agg AS (
    SELECT
        ss.ss_customer_id AS customer_id,
        ss.ss_item_id AS item_id,
        ss.ss_quantity AS quantity,
        ss.ss_store_id AS store_id
    FROM store_sales ss
),
web_sales_agg AS (
    SELECT
        ws.ws_customer_id AS customer_id,
        ws.ws_item_id AS item_id,
        ws.ws_quantity AS quantity,
        CAST(NULL AS bigint) AS store_id
    FROM web_sales ws
),
combined_sales AS (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
)
SELECT
    c.c_name,
    sum(cs.quantity) AS total_quantity,
    sum(cs.quantity * i.i_price) AS total_spent,
    count(distinct cs.store_id) FILTER (WHERE cs.store_id IS NOT NULL) AS distinct_store_count,
    sum(cs.quantity * coalesce(ir.avg_rating, 0)) / nullif(sum(cs.quantity), 0) AS weighted_avg_rating
FROM combined_sales cs
JOIN customers c
    ON cs.customer_id = c.c_customer_id
JOIN items i
    ON cs.item_id = i.i_item_id
LEFT JOIN item_ratings ir
    ON i.i_item_id = ir.pr_item_id
GROUP BY c.c_name
ORDER BY total_spent DESC
LIMIT 10
