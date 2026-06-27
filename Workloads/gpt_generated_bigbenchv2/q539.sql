WITH store_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS total_store_quantity,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_store_customers
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
web_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS total_web_quantity,
        COUNT(DISTINCT ws.ws_customer_id) AS distinct_web_customers
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
reviews_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
items_agg AS (
    SELECT
        i_category_id,
        i_category_name,
        AVG(i_price) AS avg_price,
        COUNT(*) AS item_count
    FROM items
    GROUP BY i_category_id, i_category_name
)
SELECT
    iag.i_category_id AS category_id,
    iag.i_category_name AS category_name,
    s.total_store_quantity,
    w.total_web_quantity,
    r.avg_rating,
    iag.avg_price,
    s.distinct_store_customers,
    w.distinct_web_customers,
    r.review_count,
    iag.item_count
FROM items_agg iag
LEFT JOIN store_sales_agg s
    ON iag.i_category_id = s.i_category_id
LEFT JOIN web_sales_agg w
    ON iag.i_category_id = w.i_category_id
LEFT JOIN reviews_agg r
    ON iag.i_category_id = r.i_category_id
ORDER BY iag.i_category_id
