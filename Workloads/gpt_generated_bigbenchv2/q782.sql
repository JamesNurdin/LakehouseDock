WITH store_sales_agg AS (
    SELECT
        i.i_category_id AS i_category_id,
        i.i_category AS i_category,
        SUM(ss.ss_quantity) AS store_quantity,
        COUNT(DISTINCT ss.ss_customer_id) AS store_customer_count
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
web_sales_agg AS (
    SELECT
        i.i_category_id AS i_category_id,
        i.i_category AS i_category,
        SUM(ws.ws_quantity) AS web_quantity,
        COUNT(DISTINCT ws.ws_customer_id) AS web_customer_count
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
reviews_agg AS (
    SELECT
        i.i_category_id AS i_category_id,
        i.i_category AS i_category,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(*) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
items_price_agg AS (
    SELECT
        i_category_id,
        i_category,
        AVG(i_price) AS avg_price,
        COUNT(*) AS item_count
    FROM items
    GROUP BY i_category_id, i_category
)
SELECT
    COALESCE(ss.i_category_id, ws.i_category_id, r.i_category_id, p.i_category_id) AS category_id,
    COALESCE(ss.i_category, ws.i_category, r.i_category, p.i_category) AS category_name,
    COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0) AS total_quantity_sold,
    COALESCE(ss.store_customer_count, 0) + COALESCE(ws.web_customer_count, 0) AS total_customer_count,
    r.avg_sentiment,
    COALESCE(r.review_count, 0) AS total_reviews,
    p.avg_price,
    p.item_count
FROM store_sales_agg ss
FULL OUTER JOIN web_sales_agg ws
    ON ss.i_category_id = ws.i_category_id
FULL OUTER JOIN reviews_agg r
    ON COALESCE(ss.i_category_id, ws.i_category_id) = r.i_category_id
FULL OUTER JOIN items_price_agg p
    ON COALESCE(ss.i_category_id, ws.i_category_id, r.i_category_id) = p.i_category_id
ORDER BY total_quantity_sold DESC
LIMIT 10
