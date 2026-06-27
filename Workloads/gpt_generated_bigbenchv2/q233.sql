WITH sales_union AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        ss.ss_quantity AS quantity,
        ss.ss_quantity * i.i_price AS revenue
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id

    UNION ALL

    SELECT
        i.i_category_id,
        i.i_category_name,
        ws.ws_quantity AS quantity,
        ws.ws_quantity * i.i_price AS revenue
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
),

sales_agg AS (
    SELECT
        i_category_id,
        i_category_name,
        SUM(quantity) AS total_quantity,
        SUM(revenue) AS total_revenue
    FROM sales_union
    GROUP BY i_category_id, i_category_name
),

rating_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),

customers_union AS (
    SELECT
        ss.ss_customer_id AS customer_id,
        i.i_category_id,
        i.i_category_name
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id

    UNION

    SELECT
        ws.ws_customer_id AS customer_id,
        i.i_category_id,
        i.i_category_name
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
),

customers_agg AS (
    SELECT
        i_category_id,
        i_category_name,
        COUNT(DISTINCT customer_id) AS distinct_customers
    FROM customers_union
    GROUP BY i_category_id, i_category_name
)

SELECT
    s.i_category_id,
    s.i_category_name,
    s.total_quantity,
    s.total_revenue,
    c.distinct_customers,
    r.avg_rating,
    r.review_count
FROM sales_agg s
LEFT JOIN rating_agg r
    ON s.i_category_id = r.i_category_id
   AND s.i_category_name = r.i_category_name
LEFT JOIN customers_agg c
    ON s.i_category_id = c.i_category_id
   AND s.i_category_name = c.i_category_name
ORDER BY s.total_revenue DESC
