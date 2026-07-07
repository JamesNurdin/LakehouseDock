WITH store_sales_data AS (
    SELECT
        i.i_category AS category,
        ss.ss_quantity AS quantity,
        i.i_price AS price,
        pr.pr_sentiment AS sentiment,
        c.c_customer_id AS customer_id
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    LEFT JOIN product_reviews pr ON i.i_item_id = pr.pr_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
),
web_sales_data AS (
    SELECT
        i.i_category AS category,
        ws.ws_quantity AS quantity,
        i.i_price AS price,
        pr.pr_sentiment AS sentiment,
        c.c_customer_id AS customer_id
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    LEFT JOIN product_reviews pr ON i.i_item_id = pr.pr_item_id
)
SELECT
    category,
    SUM(quantity) AS total_quantity_sold,
    AVG(price) AS average_item_price,
    AVG(sentiment) AS average_review_sentiment,
    COUNT(DISTINCT customer_id) AS distinct_customers
FROM (
    SELECT
        category,
        quantity,
        price,
        sentiment,
        customer_id
    FROM store_sales_data
    UNION ALL
    SELECT
        category,
        quantity,
        price,
        sentiment,
        customer_id
    FROM web_sales_data
) AS all_sales
GROUP BY category
ORDER BY total_quantity_sold DESC
