WITH store_agg AS (
    SELECT
        ss_customer_id,
        ss_item_id,
        SUM(ss_quantity) AS store_quantity,
        SUM(ss_quantity * i_price) AS store_revenue
    FROM store_sales
    JOIN items ON store_sales.ss_item_id = items.i_item_id
    GROUP BY ss_customer_id, ss_item_id
),
web_agg AS (
    SELECT
        ws_customer_id,
        ws_item_id,
        SUM(ws_quantity) AS web_quantity,
        SUM(ws_quantity * i_price) AS web_revenue
    FROM web_sales
    JOIN items ON web_sales.ws_item_id = items.i_item_id
    GROUP BY ws_customer_id, ws_item_id
),
review_agg AS (
    SELECT
        pr_item_id,
        COUNT(*) AS review_count,
        AVG(pr_rating) AS avg_rating
    FROM product_reviews
    GROUP BY pr_item_id
)
SELECT
    COALESCE(sa.ss_customer_id, wa.ws_customer_id) AS c_customer_id,
    c.c_name,
    COALESCE(sa.ss_item_id, wa.ws_item_id) AS i_item_id,
    i.i_name,
    i.i_category_id,
    i.i_category_name,
    COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity,
    COALESCE(sa.store_revenue, 0) + COALESCE(wa.web_revenue, 0) AS total_revenue,
    COALESCE(r.review_count, 0) AS review_count,
    r.avg_rating
FROM store_agg sa
FULL OUTER JOIN web_agg wa
    ON sa.ss_customer_id = wa.ws_customer_id
   AND sa.ss_item_id = wa.ws_item_id
JOIN customers c
    ON c.c_customer_id = COALESCE(sa.ss_customer_id, wa.ws_customer_id)
JOIN items i
    ON i.i_item_id = COALESCE(sa.ss_item_id, wa.ws_item_id)
LEFT JOIN review_agg r
    ON r.pr_item_id = i.i_item_id
WHERE (COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0)) > 0
ORDER BY total_revenue DESC
LIMIT 100
