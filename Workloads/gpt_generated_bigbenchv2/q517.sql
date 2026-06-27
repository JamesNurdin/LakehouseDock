WITH store_sales_agg AS (
    SELECT
        ss.ss_store_id                     AS store_id,
        s.s_store_name                     AS store_name,
        i.i_category_id                    AS category_id,
        i.i_category_name                  AS category_name,
        SUM(ss.ss_quantity)               AS total_quantity_store,
        SUM(ss.ss_quantity * i.i_price)   AS total_revenue_store,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers_store
    FROM store_sales ss
    JOIN stores s      ON ss.ss_store_id = s.s_store_id
    JOIN items i       ON ss.ss_item_id = i.i_item_id
    GROUP BY
        ss.ss_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category_name
),
web_sales_agg AS (
    SELECT
        i.i_category_id                    AS category_id,
        i.i_category_name                  AS category_name,
        SUM(ws.ws_quantity)               AS total_quantity_web,
        SUM(ws.ws_quantity * i.i_price)   AS total_revenue_web,
        COUNT(DISTINCT ws.ws_customer_id) AS distinct_customers_web
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY
        i.i_category_id,
        i.i_category_name
),
reviews_agg AS (
    SELECT
        i.i_category_id   AS category_id,
        i.i_category_name AS category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*)          AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY
        i.i_category_id,
        i.i_category_name
)
SELECT
    ss.store_id,
    ss.store_name,
    ss.category_id,
    ss.category_name,
    ss.total_quantity_store,
    ss.total_revenue_store,
    COALESCE(ws.total_quantity_web, 0) AS total_quantity_web,
    COALESCE(ws.total_revenue_web, 0)   AS total_revenue_web,
    COALESCE(r.avg_rating, 0)          AS avg_rating,
    COALESCE(r.review_count, 0)        AS review_count,
    ss.distinct_customers_store,
    ws.distinct_customers_web
FROM store_sales_agg ss
LEFT JOIN web_sales_agg ws
    ON ss.category_id = ws.category_id
   AND ss.category_name = ws.category_name
LEFT JOIN reviews_agg r
    ON ss.category_id = r.category_id
   AND ss.category_name = r.category_name
ORDER BY ss.total_revenue_store DESC
LIMIT 100
