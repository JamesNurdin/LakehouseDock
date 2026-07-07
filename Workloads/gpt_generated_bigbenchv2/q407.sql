WITH sales_data AS (
    SELECT
        ss.ss_customer_id AS customer_id,
        ss.ss_item_id AS item_id,
        ss.ss_quantity AS quantity,
        'store' AS channel
    FROM store_sales ss
    UNION ALL
    SELECT
        ws.ws_customer_id AS customer_id,
        ws.ws_item_id AS item_id,
        ws.ws_quantity AS quantity,
        'web' AS channel
    FROM web_sales ws
),
sales_agg AS (
    SELECT
        i.i_category,
        sd.channel,
        sum(sd.quantity) AS total_quantity,
        count(DISTINCT sd.customer_id) AS distinct_customers
    FROM sales_data sd
    JOIN customers c ON sd.customer_id = c.c_customer_id
    JOIN items i ON sd.item_id = i.i_item_id
    GROUP BY i.i_category, sd.channel
),
review_agg AS (
    SELECT
        i.i_category,
        avg(pr.pr_sentiment) AS avg_sentiment,
        count(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category
)
SELECT
    s.i_category,
    s.channel,
    s.total_quantity,
    s.distinct_customers,
    r.avg_sentiment,
    r.review_count
FROM sales_agg s
LEFT JOIN review_agg r ON s.i_category = r.i_category
ORDER BY s.i_category, s.channel
