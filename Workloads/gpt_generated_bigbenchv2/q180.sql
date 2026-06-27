WITH
store_sales_agg AS (
    SELECT i.i_category_id,
           i.i_category_name,
           SUM(ss.ss_quantity) AS store_qty
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
web_sales_agg AS (
    SELECT i.i_category_id,
           i.i_category_name,
           SUM(ws.ws_quantity) AS web_qty
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
reviews_agg AS (
    SELECT i.i_category_id,
           i.i_category_name,
           AVG(pr.pr_rating) AS avg_rating,
           COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
price_agg AS (
    SELECT i.i_category_id,
           i.i_category_name,
           AVG(i.i_price) AS avg_price
    FROM items i
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    COALESCE(ss.i_category_id, ws.i_category_id, r.i_category_id, p.i_category_id) AS category_id,
    COALESCE(ss.i_category_name, ws.i_category_name, r.i_category_name, p.i_category_name) AS category_name,
    COALESCE(ss.store_qty, 0) + COALESCE(ws.web_qty, 0) AS total_quantity,
    COALESCE(r.avg_rating, 0) AS avg_rating,
    COALESCE(r.review_count, 0) AS review_count,
    COALESCE(p.avg_price, 0) AS avg_price
FROM store_sales_agg ss
FULL OUTER JOIN web_sales_agg ws
    ON ss.i_category_id = ws.i_category_id
FULL OUTER JOIN reviews_agg r
    ON COALESCE(ss.i_category_id, ws.i_category_id) = r.i_category_id
FULL OUTER JOIN price_agg p
    ON COALESCE(ss.i_category_id, ws.i_category_id, r.i_category_id) = p.i_category_id
ORDER BY total_quantity DESC
LIMIT 10
