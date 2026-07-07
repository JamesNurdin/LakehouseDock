WITH
store_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        SUM(ss.ss_quantity) AS total_quantity_store
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
web_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        SUM(ws.ws_quantity) AS total_quantity_web
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
reviews_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
distinct_customers_count AS (
    SELECT
        i.i_category_id,
        i.i_category,
        COUNT(DISTINCT cust.cust_id) AS distinct_customers
    FROM (
        SELECT ss.ss_customer_id AS cust_id, ss.ss_item_id AS item_id
        FROM store_sales ss
        UNION
        SELECT ws.ws_customer_id AS cust_id, ws.ws_item_id AS item_id
        FROM web_sales ws
    ) cust
    JOIN items i ON cust.item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
categories AS (
    SELECT DISTINCT i_category_id, i_category
    FROM items
)
SELECT
    c.i_category_id,
    c.i_category,
    COALESCE(ssa.total_quantity_store, 0) + COALESCE(wsa.total_quantity_web, 0) AS total_quantity_sold,
    ra.avg_sentiment,
    ra.review_count,
    dcc.distinct_customers
FROM categories c
LEFT JOIN store_sales_agg ssa
    ON c.i_category_id = ssa.i_category_id
LEFT JOIN web_sales_agg wsa
    ON c.i_category_id = wsa.i_category_id
LEFT JOIN reviews_agg ra
    ON c.i_category_id = ra.i_category_id
LEFT JOIN distinct_customers_count dcc
    ON c.i_category_id = dcc.i_category_id
ORDER BY total_quantity_sold DESC
