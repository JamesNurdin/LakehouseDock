WITH store_agg AS (
    SELECT
        i.i_item_id,
        i.i_category_id,
        i.i_category_name,
        i.i_name,
        s.s_store_id,
        s.s_store_name,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_sales_amount
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY
        i.i_item_id,
        i.i_category_id,
        i.i_category_name,
        i.i_name,
        s.s_store_id,
        s.s_store_name
),
web_agg AS (
    SELECT
        i.i_item_id,
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_sales_amount
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY
        i.i_item_id,
        i.i_category_id,
        i.i_category_name
),
review_agg AS (
    SELECT
        i.i_item_id,
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY
        i.i_item_id,
        i.i_category_id,
        i.i_category_name
)
SELECT
    s.i_category_id,
    s.i_category_name,
    s.s_store_id,
    s.s_store_name,
    s.i_item_id,
    s.i_name,
    s.store_quantity,
    s.store_sales_amount,
    COALESCE(w.web_quantity, 0) AS web_quantity,
    COALESCE(w.web_sales_amount, 0) AS web_sales_amount,
    COALESCE(r.avg_rating, 0) AS avg_rating,
    COALESCE(r.review_count, 0) AS review_count,
    (COALESCE(w.web_quantity, 0) * 1.0) / NULLIF(s.store_quantity, 0) AS web_to_store_ratio
FROM store_agg s
LEFT JOIN web_agg w
    ON s.i_item_id = w.i_item_id
LEFT JOIN review_agg r
    ON s.i_item_id = r.i_item_id
ORDER BY s.store_quantity DESC
LIMIT 100
