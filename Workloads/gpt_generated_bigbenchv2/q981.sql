WITH store_sales_agg AS (
    SELECT
        ss_store_id,
        ss_item_id,
        SUM(ss_quantity) AS total_store_quantity,
        COUNT(DISTINCT ss_customer_id) AS distinct_store_customers
    FROM store_sales
    GROUP BY ss_store_id, ss_item_id
),
web_sales_agg AS (
    SELECT
        ws_item_id,
        SUM(ws_quantity) AS total_web_quantity,
        COUNT(DISTINCT ws_customer_id) AS distinct_web_customers
    FROM web_sales
    GROUP BY ws_item_id
),
review_agg AS (
    SELECT
        pr_item_id,
        COUNT(*) AS review_count,
        AVG(pr_rating) AS avg_rating
    FROM product_reviews
    GROUP BY pr_item_id
),
combined AS (
    SELECT
        s.s_store_name,
        i.i_category_name,
        i.i_name,
        i.i_price,
        COALESCE(ss.total_store_quantity, 0) AS store_quantity,
        COALESCE(ss.distinct_store_customers, 0) AS store_customer_count,
        COALESCE(ws.total_web_quantity, 0) AS web_quantity,
        COALESCE(ws.distinct_web_customers, 0) AS web_customer_count,
        COALESCE(r.review_count, 0) AS review_count,
        r.avg_rating
    FROM items i
    LEFT JOIN store_sales_agg ss
        ON i.i_item_id = ss.ss_item_id
    LEFT JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    LEFT JOIN web_sales_agg ws
        ON i.i_item_id = ws.ws_item_id
    LEFT JOIN review_agg r
        ON i.i_item_id = r.pr_item_id
    WHERE i.i_price >= 10
)
SELECT
    s_store_name,
    i_category_name,
    i_name,
    i_price,
    store_quantity,
    store_customer_count,
    web_quantity,
    web_customer_count,
    review_count,
    avg_rating,
    ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY store_quantity DESC) AS store_item_rank
FROM combined
ORDER BY s_store_name, store_item_rank
