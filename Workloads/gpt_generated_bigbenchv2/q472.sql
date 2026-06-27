WITH
store_item_agg AS (
    SELECT
        i.i_item_id,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS store_quantity,
        COUNT(DISTINCT ss.ss_customer_id) AS store_customers
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_category_id, i.i_category_name
),
web_item_agg AS (
    SELECT
        i.i_item_id,
        SUM(ws.ws_quantity) AS web_quantity,
        COUNT(DISTINCT ws.ws_customer_id) AS web_customers
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
review_item_agg AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
item_combined AS (
    SELECT
        i.i_item_id,
        i.i_category_id,
        i.i_category_name,
        COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity,
        COALESCE(s.store_customers, 0) + COALESCE(w.web_customers, 0) AS total_customers,
        r.avg_rating,
        r.review_count
    FROM items i
    LEFT JOIN store_item_agg s
        ON i.i_item_id = s.i_item_id
    LEFT JOIN web_item_agg w
        ON i.i_item_id = w.i_item_id
    LEFT JOIN review_item_agg r
        ON i.i_item_id = r.i_item_id
)
SELECT
    ic.i_category_id,
    ic.i_category_name,
    SUM(ic.total_quantity) AS category_quantity,
    SUM(ic.total_customers) AS category_customers,
    CASE
        WHEN SUM(ic.review_count) > 0
        THEN SUM(ic.avg_rating * ic.review_count) / SUM(ic.review_count)
        ELSE NULL
    END AS category_avg_rating,
    SUM(ic.review_count) AS category_review_count
FROM item_combined ic
GROUP BY ic.i_category_id, ic.i_category_name
ORDER BY category_quantity DESC
LIMIT 5
