/* Top 10 items by total revenue with review statistics */
WITH store_sales_agg AS (
    SELECT
        ss_item_id,
        sum(ss_quantity) AS store_quantity
    FROM store_sales
    GROUP BY ss_item_id
),
web_sales_agg AS (
    SELECT
        ws_item_id,
        sum(ws_quantity) AS web_quantity
    FROM web_sales
    GROUP BY ws_item_id
),
sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_category_id,
        i.i_category_name,
        i.i_price,
        coalesce(ss.store_quantity, 0) AS store_quantity,
        coalesce(ws.web_quantity, 0) AS web_quantity,
        (coalesce(ss.store_quantity, 0) + coalesce(ws.web_quantity, 0)) AS total_quantity,
        (coalesce(ss.store_quantity, 0) + coalesce(ws.web_quantity, 0)) * i.i_price AS total_revenue
    FROM items i
    LEFT JOIN store_sales_agg ss ON ss.ss_item_id = i.i_item_id
    LEFT JOIN web_sales_agg ws ON ws.ws_item_id = i.i_item_id
),
review_agg AS (
    SELECT
        i.i_item_id,
        count(pr.pr_review_id) AS review_count,
        avg(pr.pr_rating) AS avg_rating
    FROM items i
    LEFT JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
)
SELECT
    s.i_category_name,
    s.i_item_id,
    s.i_price,
    s.total_quantity,
    s.total_revenue,
    r.review_count,
    r.avg_rating
FROM sales_agg s
LEFT JOIN review_agg r ON r.i_item_id = s.i_item_id
WHERE s.total_quantity > 0
ORDER BY s.total_revenue DESC
LIMIT 10
