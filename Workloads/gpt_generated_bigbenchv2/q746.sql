WITH combined_sales AS (
    -- Combine store and web sales into a single stream
    SELECT ss.ss_customer_id AS customer_id,
           ss.ss_item_id      AS item_id,
           ss.ss_quantity    AS quantity,
           ss.ss_store_id    AS store_id,
           'store'            AS channel
    FROM store_sales ss
    UNION ALL
    SELECT ws.ws_customer_id AS customer_id,
           ws.ws_item_id      AS item_id,
           ws.ws_quantity    AS quantity,
           NULL               AS store_id,
           'web'              AS channel
    FROM web_sales ws
),

sales_with_item AS (
    -- Enrich each sale with item details (price, category, name)
    SELECT cs.customer_id,
           cs.item_id,
           cs.quantity,
           i.i_price,
           i.i_category_name,
           i.i_name,
           cs.store_id
    FROM combined_sales cs
    JOIN items i ON cs.item_id = i.i_item_id
),

item_avg_rating AS (
    -- Compute the average rating for each item
    SELECT i.i_item_id AS item_id,
           AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),

sales_with_rating AS (
    -- Attach the average rating (or 0 if no reviews) to each sale record
    SELECT swi.*,
           COALESCE(ir.avg_rating, 0) AS avg_rating
    FROM sales_with_item swi
    LEFT JOIN item_avg_rating ir ON swi.item_id = ir.item_id
)

SELECT
    swi.i_category_name               AS category,
    COUNT(DISTINCT swi.customer_id)   AS distinct_customers,
    SUM(swi.quantity)                 AS total_quantity_sold,
    SUM(swi.quantity * swi.i_price)   AS total_revenue,
    AVG(swi.avg_rating)               AS avg_item_rating
FROM sales_with_rating swi
GROUP BY swi.i_category_name
ORDER BY total_revenue DESC
LIMIT 10
