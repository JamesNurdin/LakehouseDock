WITH
store_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        SUM(ss.ss_quantity) AS store_quantity,
        COUNT(DISTINCT ss.ss_customer_id) AS store_customers
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
web_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        SUM(ws.ws_quantity) AS web_quantity,
        COUNT(DISTINCT ws.ws_customer_id) AS web_customers
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
),
reviews_agg AS (
    SELECT
        i.i_category_id,
        i.i_category,
        AVG(pr.pr_sentiment) AS avg_sentiment,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category
)
SELECT
    COALESCE(ssa.i_category_id, wsa.i_category_id, ra.i_category_id) AS category_id,
    COALESCE(ssa.i_category, wsa.i_category, ra.i_category) AS category_name,
    COALESCE(ssa.store_quantity, 0) + COALESCE(wsa.web_quantity, 0) AS total_quantity_sold,
    COALESCE(ssa.store_customers, 0) + COALESCE(wsa.web_customers, 0) AS total_unique_customers,
    ra.avg_sentiment,
    ra.review_count
FROM store_sales_agg ssa
FULL OUTER JOIN web_sales_agg wsa
    ON ssa.i_category_id = wsa.i_category_id
FULL OUTER JOIN reviews_agg ra
    ON COALESCE(ssa.i_category_id, wsa.i_category_id) = ra.i_category_id
ORDER BY total_quantity_sold DESC
LIMIT 100
