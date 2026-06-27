WITH store_sales_agg AS (
    SELECT
        ss.ss_store_id,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS total_quantity,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY
        ss.ss_store_id,
        i.i_category_id,
        i.i_category_name
),
web_sales_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_customer_id) AS distinct_customers
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY
        i.i_category_id,
        i.i_category_name
),
review_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY
        i.i_category_id,
        i.i_category_name
)
SELECT
    s.s_store_id,
    s.s_store_name,
    ss_agg.i_category_id,
    ss_agg.i_category_name,
    ss_agg.total_quantity AS total_store_quantity,
    ss_agg.distinct_customers AS distinct_store_customers,
    COALESCE(ws_agg.total_quantity, 0) AS total_web_quantity,
    COALESCE(ws_agg.distinct_customers, 0) AS distinct_web_customers,
    r_agg.avg_rating,
    r_agg.review_count
FROM store_sales_agg ss_agg
JOIN stores s
    ON ss_agg.ss_store_id = s.s_store_id
LEFT JOIN web_sales_agg ws_agg
    ON ss_agg.i_category_id = ws_agg.i_category_id
LEFT JOIN review_agg r_agg
    ON ss_agg.i_category_id = r_agg.i_category_id
ORDER BY
    s.s_store_name,
    ss_agg.i_category_name
