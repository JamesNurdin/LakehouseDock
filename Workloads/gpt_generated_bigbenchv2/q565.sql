WITH
    store_agg AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            SUM(ss.ss_quantity) AS store_quantity,
            COUNT(DISTINCT ss.ss_customer_id) AS store_customers,
            COUNT(DISTINCT ss.ss_store_id) AS store_count
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        GROUP BY i.i_category_id, i.i_category_name
    ),
    web_agg AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            SUM(ws.ws_quantity) AS web_quantity,
            COUNT(DISTINCT ws.ws_customer_id) AS web_customers
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        GROUP BY i.i_category_id, i.i_category_name
    ),
    review_agg AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            AVG(pr.pr_rating) AS avg_rating,
            COUNT(pr.pr_review_id) AS review_count
        FROM product_reviews pr
        JOIN items i ON pr.pr_item_id = i.i_item_id
        GROUP BY i.i_category_id, i.i_category_name
    ),
    avg_price_agg AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            AVG(i.i_price) AS avg_price
        FROM items i
        GROUP BY i.i_category_id, i.i_category_name
    ),
    distinct_customers_agg AS (
        SELECT
            cat.i_category_id,
            cat.i_category_name,
            COUNT(DISTINCT cust_id) AS distinct_customers
        FROM (
            SELECT
                i.i_category_id,
                i.i_category_name,
                ss.ss_customer_id AS cust_id
            FROM store_sales ss
            JOIN items i ON ss.ss_item_id = i.i_item_id
            UNION ALL
            SELECT
                i.i_category_id,
                i.i_category_name,
                ws.ws_customer_id AS cust_id
            FROM web_sales ws
            JOIN items i ON ws.ws_item_id = i.i_item_id
        ) cat
        GROUP BY cat.i_category_id, cat.i_category_name
    ),
    category_base AS (
        SELECT DISTINCT i.i_category_id, i.i_category_name
        FROM items i
    )
SELECT
    cb.i_category_id,
    cb.i_category_name,
    ap.avg_price,
    COALESCE(sa.store_quantity, 0) AS store_quantity,
    COALESCE(wa.web_quantity, 0) AS web_quantity,
    COALESCE(sa.store_quantity, 0) + COALESCE(wa.web_quantity, 0) AS total_quantity,
    COALESCE(sa.store_customers, 0) AS store_customers,
    COALESCE(wa.web_customers, 0) AS web_customers,
    COALESCE(dca.distinct_customers, 0) AS distinct_customers,
    COALESCE(sa.store_count, 0) AS store_count,
    COALESCE(ra.avg_rating, 0) AS avg_rating,
    COALESCE(ra.review_count, 0) AS review_count
FROM category_base cb
LEFT JOIN avg_price_agg ap ON cb.i_category_id = ap.i_category_id
LEFT JOIN store_agg sa ON cb.i_category_id = sa.i_category_id
LEFT JOIN web_agg wa ON cb.i_category_id = wa.i_category_id
LEFT JOIN review_agg ra ON cb.i_category_id = ra.i_category_id
LEFT JOIN distinct_customers_agg dca ON cb.i_category_id = dca.i_category_id
ORDER BY total_quantity DESC
LIMIT 10
