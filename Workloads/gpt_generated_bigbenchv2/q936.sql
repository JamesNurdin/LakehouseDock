WITH store_agg AS (
    SELECT
        ss_item_id,
        sum(ss_quantity) AS store_quantity,
        sum(ss_quantity * i_price) AS store_revenue
    FROM store_sales
    JOIN items ON store_sales.ss_item_id = items.i_item_id
    GROUP BY ss_item_id
),
web_agg AS (
    SELECT
        ws_item_id,
        sum(ws_quantity) AS web_quantity,
        sum(ws_quantity * i_price) AS web_revenue
    FROM web_sales
    JOIN items ON web_sales.ws_item_id = items.i_item_id
    GROUP BY ws_item_id
),
review_agg AS (
    SELECT
        pr_item_id,
        count(*) AS review_count,
        avg(pr_rating) AS avg_rating
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    i.i_item_id,
    i.i_name,
    i.i_category_name,
    coalesce(sa.store_quantity, 0) + coalesce(wa.web_quantity, 0) AS total_quantity_sold,
    coalesce(sa.store_revenue, 0) + coalesce(wa.web_revenue, 0) AS total_revenue,
    ra.review_count,
    ra.avg_rating
FROM items i
LEFT JOIN store_agg sa ON i.i_item_id = sa.ss_item_id
LEFT JOIN web_agg wa ON i.i_item_id = wa.ws_item_id
LEFT JOIN review_agg ra ON i.i_item_id = ra.pr_item_id
ORDER BY total_revenue DESC
LIMIT 10
