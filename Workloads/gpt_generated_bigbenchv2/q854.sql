WITH store_agg AS (
    SELECT
        i.i_item_id,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_sales_amount
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
web_agg AS (
    SELECT
        i.i_item_id,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_sales_amount
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
review_agg AS (
    SELECT
        pr.pr_item_id AS i_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
)
SELECT
    i.i_category_id,
    i.i_category_name,
    SUM(COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0)) AS total_quantity_sold,
    SUM(COALESCE(sa.store_sales_amount, 0) + COALESCE(wa.web_sales_amount, 0)) AS total_sales_amount,
    AVG(ra.avg_rating) AS avg_rating,
    SUM(ra.review_count) AS total_review_count
FROM items i
LEFT JOIN store_agg sa
    ON i.i_item_id = sa.i_item_id
LEFT JOIN web_agg wa
    ON i.i_item_id = wa.i_item_id
LEFT JOIN review_agg ra
    ON i.i_item_id = ra.i_item_id
GROUP BY i.i_category_id, i.i_category_name
ORDER BY total_quantity_sold DESC
LIMIT 10
