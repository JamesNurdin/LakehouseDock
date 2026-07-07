WITH sales AS (
    SELECT
        ss.ss_item_id AS item_id,
        ss.ss_quantity AS quantity,
        ss.ss_customer_id AS customer_id,
        i.i_category_id AS category_id,
        i.i_category AS category,
        i.i_price AS price
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT
        ws.ws_item_id AS item_id,
        ws.ws_quantity AS quantity,
        ws.ws_customer_id AS customer_id,
        i.i_category_id AS category_id,
        i.i_category AS category,
        i.i_price AS price
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
),
sales_agg AS (
    SELECT
        category_id,
        category,
        SUM(quantity) AS total_quantity,
        SUM(quantity * price) AS total_revenue,
        COUNT(DISTINCT customer_id) AS distinct_customers
    FROM sales
    GROUP BY category_id, category
),
reviews AS (
    SELECT
        i.i_category_id AS category_id,
        i.i_category AS category,
        pr.pr_sentiment AS sentiment
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
),
review_agg AS (
    SELECT
        category_id,
        category,
        AVG(sentiment) AS avg_sentiment
    FROM reviews
    GROUP BY category_id, category
)
SELECT
    s.category_id,
    s.category,
    s.total_quantity,
    s.total_revenue,
    s.distinct_customers,
    r.avg_sentiment
FROM sales_agg s
LEFT JOIN review_agg r
    ON s.category_id = r.category_id
    AND s.category = r.category
ORDER BY s.total_quantity DESC
