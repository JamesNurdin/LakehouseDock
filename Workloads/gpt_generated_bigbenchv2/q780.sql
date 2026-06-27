WITH
    sales_union AS (
        SELECT ss.ss_item_id AS item_id,
               ss.ss_quantity AS quantity,
               i.i_price AS price
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        UNION ALL
        SELECT ws.ws_item_id AS item_id,
               ws.ws_quantity AS quantity,
               i.i_price AS price
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
    ),
    sales_agg AS (
        SELECT
            item_id,
            SUM(quantity) AS total_quantity,
            SUM(quantity * price) AS total_revenue
        FROM sales_union
        GROUP BY item_id
    ),
    customers_union AS (
        SELECT ss.ss_item_id AS item_id,
               ss.ss_customer_id AS customer_id
        FROM store_sales ss
        UNION
        SELECT ws.ws_item_id AS item_id,
               ws.ws_customer_id AS customer_id
        FROM web_sales ws
    ),
    customers_agg AS (
        SELECT
            item_id,
            COUNT(DISTINCT customer_id) AS distinct_customer_count
        FROM customers_union
        GROUP BY item_id
    ),
    reviews_agg AS (
        SELECT
            pr.pr_item_id AS item_id,
            SUM(pr.pr_rating) AS rating_sum,
            COUNT(*) AS rating_count
        FROM product_reviews pr
        GROUP BY pr.pr_item_id
    )
SELECT
    i.i_category_name,
    SUM(COALESCE(s.total_quantity, 0)) AS category_quantity_sold,
    SUM(COALESCE(s.total_revenue, 0)) AS category_total_revenue,
    SUM(COALESCE(r.rating_sum, 0)) / NULLIF(SUM(COALESCE(r.rating_count, 0)), 0) AS category_avg_rating,
    SUM(COALESCE(c.distinct_customer_count, 0)) AS category_distinct_customers,
    COUNT(DISTINCT i.i_item_id) AS distinct_items_sold
FROM items i
LEFT JOIN sales_agg s ON s.item_id = i.i_item_id
LEFT JOIN customers_agg c ON c.item_id = i.i_item_id
LEFT JOIN reviews_agg r ON r.item_id = i.i_item_id
GROUP BY i.i_category_name
ORDER BY category_total_revenue DESC
LIMIT 10
