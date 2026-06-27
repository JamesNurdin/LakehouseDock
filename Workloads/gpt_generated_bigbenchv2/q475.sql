WITH item_ratings AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
store_category_sales AS (
    SELECT
        ss.ss_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers,
        SUM(ss.ss_quantity * r.avg_rating) AS rating_quantity_weighted,
        SUM(CASE WHEN r.avg_rating IS NOT NULL THEN ss.ss_quantity ELSE 0 END) AS rating_quantity_sum
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    LEFT JOIN item_ratings r
        ON i.i_item_id = r.i_item_id
    GROUP BY
        ss.ss_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category_name
),
web_category_sales AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue,
        COUNT(DISTINCT ws.ws_customer_id) AS web_distinct_customers
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY
        i.i_category_id,
        i.i_category_name
)
SELECT
    scs.ss_store_id,
    scs.s_store_name,
    scs.i_category_id,
    scs.i_category_name,
    scs.total_quantity,
    scs.total_revenue,
    scs.distinct_customers,
    COALESCE(wcs.web_quantity, 0) AS web_quantity,
    COALESCE(wcs.web_revenue, 0) AS web_revenue,
    COALESCE(wcs.web_distinct_customers, 0) AS web_distinct_customers,
    scs.total_quantity + COALESCE(wcs.web_quantity, 0) AS total_quantity_all_channels,
    scs.total_revenue + COALESCE(wcs.web_revenue, 0) AS total_revenue_all_channels,
    CASE
        WHEN scs.rating_quantity_sum > 0 THEN scs.rating_quantity_weighted / scs.rating_quantity_sum
        ELSE NULL
    END AS avg_rating_weighted
FROM store_category_sales scs
LEFT JOIN web_category_sales wcs
    ON scs.i_category_id = wcs.i_category_id
    AND scs.i_category_name = wcs.i_category_name
ORDER BY total_revenue_all_channels DESC
LIMIT 20
