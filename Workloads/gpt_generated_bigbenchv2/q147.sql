WITH store_sales_joined AS (
    SELECT
        i.i_category AS category,
        i.i_category_id AS category_id,
        ss.ss_quantity AS quantity,
        i.i_price AS price
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
),
web_sales_joined AS (
    SELECT
        i.i_category AS category,
        i.i_category_id AS category_id,
        ws.ws_quantity AS quantity,
        i.i_price AS price
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
all_sales AS (
    SELECT category, category_id, quantity, price FROM store_sales_joined
    UNION ALL
    SELECT category, category_id, quantity, price FROM web_sales_joined
),
sales_agg AS (
    SELECT
        category,
        category_id,
        SUM(quantity) AS total_quantity,
        SUM(quantity * price) AS total_revenue
    FROM all_sales
    GROUP BY category, category_id
),
reviews_agg AS (
    SELECT
        i.i_category AS category,
        i.i_category_id AS category_id,
        AVG(pr.pr_sentiment) AS avg_sentiment
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category, i.i_category_id
)
SELECT
    s.category,
    s.category_id,
    s.total_quantity,
    s.total_revenue,
    r.avg_sentiment
FROM sales_agg s
LEFT JOIN reviews_agg r
    ON s.category = r.category
    AND s.category_id = r.category_id
ORDER BY s.total_revenue DESC
LIMIT 10
