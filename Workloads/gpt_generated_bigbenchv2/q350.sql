WITH combined_sales AS (
    SELECT ss_item_id AS item_id, ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT ws_item_id AS item_id, ws_quantity AS quantity
    FROM web_sales
),
sales_agg AS (
    SELECT
        cs.item_id,
        SUM(cs.quantity) AS total_quantity,
        SUM(cs.quantity * i.i_price) AS total_revenue
    FROM combined_sales cs
    JOIN items i ON cs.item_id = i.i_item_id
    GROUP BY cs.item_id
),
rating_agg AS (
    SELECT
        pr_item_id AS item_id,
        AVG(pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews
    GROUP BY pr_item_id
),
customer_agg AS (
    SELECT
        ic.item_id,
        COUNT(DISTINCT ic.customer_id) AS distinct_customer_count
    FROM (
        SELECT ss_item_id AS item_id, ss_customer_id AS customer_id
        FROM store_sales
        UNION
        SELECT ws_item_id AS item_id, ws_customer_id AS customer_id
        FROM web_sales
    ) ic
    GROUP BY ic.item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_name,
    sa.total_quantity,
    sa.total_revenue,
    COALESCE(ra.avg_rating, 0) AS avg_rating,
    COALESCE(ra.review_count, 0) AS review_count,
    COALESCE(ca.distinct_customer_count, 0) AS distinct_customer_count
FROM items i
LEFT JOIN sales_agg sa ON i.i_item_id = sa.item_id
LEFT JOIN rating_agg ra ON i.i_item_id = ra.item_id
LEFT JOIN customer_agg ca ON i.i_item_id = ca.item_id
ORDER BY sa.total_revenue DESC
LIMIT 10
