WITH store_agg AS (
    SELECT
        i.i_item_id,
        i.i_name,
        i.i_category_id,
        i.i_category_name,
        i.i_price,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_sales_amount
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_name, i.i_category_id, i.i_category_name, i.i_price
),
web_agg AS (
    SELECT
        i.i_item_id,
        i.i_name,
        i.i_category_id,
        i.i_category_name,
        i.i_price,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_sales_amount
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_name, i.i_category_id, i.i_category_name, i.i_price
),
review_agg AS (
    SELECT
        i.i_item_id,
        i.i_name,
        i.i_category_id,
        i.i_category_name,
        i.i_price,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_name, i.i_category_id, i.i_category_name, i.i_price
)
SELECT
    COALESCE(sa.i_item_id, wa.i_item_id, ra.i_item_id) AS i_item_id,
    COALESCE(sa.i_name, wa.i_name, ra.i_name) AS i_name,
    COALESCE(sa.i_category_id, wa.i_category_id, ra.i_category_id) AS i_category_id,
    COALESCE(sa.i_category_name, wa.i_category_name, ra.i_category_name) AS i_category_name,
    COALESCE(sa.i_price, wa.i_price, ra.i_price) AS i_price,
    COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity,
    COALESCE(sa.store_sales_amount, 0) + COALESCE(wa.web_sales_amount, 0) AS total_sales_amount,
    ra.avg_rating,
    ra.review_count
FROM store_agg sa
FULL OUTER JOIN web_agg wa ON sa.i_item_id = wa.i_item_id
LEFT JOIN review_agg ra ON COALESCE(sa.i_item_id, wa.i_item_id) = ra.i_item_id
ORDER BY total_sales_amount DESC
LIMIT 10
