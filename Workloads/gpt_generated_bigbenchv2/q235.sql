WITH all_sales_detail AS (
    SELECT
        ss.ss_item_id AS item_id,
        ss.ss_quantity AS quantity,
        ss.ss_customer_id AS customer_id,
        i.i_price AS price,
        i.i_category_id,
        i.i_category_name
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id

    UNION ALL

    SELECT
        ws.ws_item_id AS item_id,
        ws.ws_quantity AS quantity,
        ws.ws_customer_id AS customer_id,
        i.i_price AS price,
        i.i_category_id,
        i.i_category_name
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
),

sales_by_category AS (
    SELECT
        i_category_id,
        i_category_name,
        SUM(quantity) AS total_quantity,
        SUM(quantity * price) AS total_revenue,
        COUNT(DISTINCT customer_id) AS distinct_customers
    FROM all_sales_detail
    GROUP BY i_category_id, i_category_name
),

rating_by_category AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)

SELECT
    s.i_category_id,
    s.i_category_name,
    s.total_quantity,
    s.total_revenue,
    s.distinct_customers,
    r.avg_rating,
    r.review_count
FROM sales_by_category s
LEFT JOIN rating_by_category r
    ON s.i_category_id = r.i_category_id
   AND s.i_category_name = r.i_category_name
ORDER BY s.total_revenue DESC
LIMIT 10
