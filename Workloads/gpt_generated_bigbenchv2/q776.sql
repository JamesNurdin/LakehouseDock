WITH
    store_agg AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            SUM(ss.ss_quantity) AS store_quantity,
            SUM(i.i_price * ss.ss_quantity) AS store_price_quantity,
            COUNT(DISTINCT ss.ss_store_id) AS distinct_store_count
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        JOIN stores s ON ss.ss_store_id = s.s_store_id
        GROUP BY i.i_category_id, i.i_category_name
    ),
    web_agg AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            SUM(ws.ws_quantity) AS web_quantity,
            SUM(i.i_price * ws.ws_quantity) AS web_price_quantity
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
    customer_agg AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            c.c_customer_id
        FROM store_sales ss
        JOIN customers c ON ss.ss_customer_id = c.c_customer_id
        JOIN items i ON ss.ss_item_id = i.i_item_id
        UNION
        SELECT
            i.i_category_id,
            i.i_category_name,
            c.c_customer_id
        FROM web_sales ws
        JOIN customers c ON ws.ws_customer_id = c.c_customer_id
        JOIN items i ON ws.ws_item_id = i.i_item_id
    ),
    customer_counts AS (
        SELECT
            i_category_id,
            i_category_name,
            COUNT(DISTINCT c_customer_id) AS distinct_customer_count
        FROM customer_agg
        GROUP BY i_category_id, i_category_name
    )
SELECT
    COALESCE(s.i_category_id, w.i_category_id, r.i_category_id, c.i_category_id) AS category_id,
    COALESCE(s.i_category_name, w.i_category_name, r.i_category_name, c.i_category_name) AS category_name,
    COALESCE(s.store_quantity, 0) AS store_quantity,
    COALESCE(w.web_quantity, 0) AS web_quantity,
    COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity,
    CASE
        WHEN (COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0)) = 0 THEN NULL
        ELSE (COALESCE(s.store_price_quantity, 0) + COALESCE(w.web_price_quantity, 0))
             / (COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0))
    END AS weighted_avg_price,
    COALESCE(c.distinct_customer_count, 0) AS distinct_customer_count,
    COALESCE(s.distinct_store_count, 0) AS distinct_store_count,
    r.avg_rating,
    r.review_count
FROM store_agg s
FULL OUTER JOIN web_agg w
    ON s.i_category_id = w.i_category_id
FULL OUTER JOIN review_agg r
    ON COALESCE(s.i_category_id, w.i_category_id) = r.i_category_id
FULL OUTER JOIN customer_counts c
    ON COALESCE(s.i_category_id, w.i_category_id) = c.i_category_id
ORDER BY total_quantity DESC
LIMIT 10
