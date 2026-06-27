WITH item_store_agg AS (
    SELECT
        ss.ss_item_id AS i_item_id,
        SUM(ss.ss_quantity) AS store_qty,
        SUM(i.i_price * ss.ss_quantity) AS store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_item_id
),
item_web_agg AS (
    SELECT
        ws.ws_item_id AS i_item_id,
        SUM(ws.ws_quantity) AS web_qty
    FROM web_sales ws
    GROUP BY ws.ws_item_id
),
item_review_agg AS (
    SELECT
        pr.pr_item_id AS i_item_id,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
category_store_distinct AS (
    SELECT
        i.i_category_id AS category_id,
        COUNT(DISTINCT ss.ss_store_id) AS distinct_store_cnt
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id
)
SELECT
    i.i_category_id,
    i.i_category_name,
    SUM(COALESCE(isa.store_qty, 0)) AS total_store_quantity,
    SUM(COALESCE(iwa.web_qty, 0)) AS total_web_quantity,
    SUM(COALESCE(isa.store_revenue, 0)) AS total_store_revenue,
    AVG(ira.avg_rating) AS avg_item_rating,
    COALESCE(csd.distinct_store_cnt, 0) AS distinct_store_count
FROM items i
LEFT JOIN item_store_agg isa ON i.i_item_id = isa.i_item_id
LEFT JOIN item_web_agg iwa ON i.i_item_id = iwa.i_item_id
LEFT JOIN item_review_agg ira ON i.i_item_id = ira.i_item_id
LEFT JOIN category_store_distinct csd ON i.i_category_id = csd.category_id
GROUP BY i.i_category_id, i.i_category_name, csd.distinct_store_cnt
ORDER BY total_store_revenue DESC
LIMIT 10
