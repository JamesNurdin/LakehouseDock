WITH store_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS total_quantity_store,
        SUM(i.i_price * ss.ss_quantity) AS total_revenue_store
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
web_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS total_quantity_web,
        SUM(i.i_price * ws.ws_quantity) AS total_revenue_web
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
rating_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS average_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
customer_agg AS (
    SELECT
        cat.i_category_id,
        cat.i_category_name,
        COUNT(DISTINCT cat.c_customer_id) AS distinct_customers
    FROM (
        SELECT ss.ss_customer_id AS c_customer_id, i.i_category_id, i.i_category_name
        FROM store_sales ss
        JOIN items i
            ON ss.ss_item_id = i.i_item_id
        UNION ALL
        SELECT ws.ws_customer_id AS c_customer_id, i.i_category_id, i.i_category_name
        FROM web_sales ws
        JOIN items i
            ON ws.ws_item_id = i.i_item_id
    ) cat
    GROUP BY cat.i_category_id, cat.i_category_name
)
SELECT
    COALESCE(s.i_category_id, w.i_category_id, r.i_category_id, c.i_category_id) AS category_id,
    COALESCE(s.i_category_name, w.i_category_name, r.i_category_name, c.i_category_name) AS category_name,
    s.total_quantity_store,
    w.total_quantity_web,
    s.total_revenue_store,
    w.total_revenue_web,
    r.average_rating,
    c.distinct_customers
FROM store_agg s
FULL OUTER JOIN web_agg w
    ON s.i_category_id = w.i_category_id
FULL OUTER JOIN rating_agg r
    ON COALESCE(s.i_category_id, w.i_category_id) = r.i_category_id
FULL OUTER JOIN customer_agg c
    ON COALESCE(s.i_category_id, w.i_category_id, r.i_category_id) = c.i_category_id
ORDER BY (COALESCE(s.total_revenue_store, 0) + COALESCE(w.total_revenue_web, 0)) DESC
LIMIT 20
