WITH item_store_sales AS (
    SELECT
        ss.ss_store_id,
        i.i_item_id,
        i.i_name,
        i.i_category_name,
        SUM(ss.ss_quantity) AS store_quantity,
        SUM(ss.ss_quantity * i.i_price) AS store_revenue
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    GROUP BY
        ss.ss_store_id,
        i.i_item_id,
        i.i_name,
        i.i_category_name
),
item_web_sales AS (
    SELECT
        i.i_item_id,
        SUM(ws.ws_quantity) AS web_quantity,
        SUM(ws.ws_quantity * i.i_price) AS web_revenue
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY
        i.i_item_id
),
item_ratings AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY
        i.i_item_id
),
store_names AS (
    SELECT
        s_store_id,
        s_store_name
    FROM stores
)
SELECT
    t.store_name,
    t.i_item_id,
    t.i_name,
    t.i_category_name,
    t.store_quantity,
    t.store_revenue,
    t.web_quantity,
    t.web_revenue,
    t.total_revenue,
    t.avg_rating,
    t.review_count,
    t.rank
FROM (
    SELECT
        s.s_store_name AS store_name,
        iss.i_item_id,
        iss.i_name,
        iss.i_category_name,
        iss.store_quantity,
        iss.store_revenue,
        COALESCE(iws.web_quantity, 0) AS web_quantity,
        COALESCE(iws.web_revenue, 0) AS web_revenue,
        COALESCE(iss.store_revenue, 0) + COALESCE(iws.web_revenue, 0) AS total_revenue,
        ir.avg_rating,
        ir.review_count,
        ROW_NUMBER() OVER (
            PARTITION BY s.s_store_id
            ORDER BY COALESCE(iss.store_revenue, 0) + COALESCE(iws.web_revenue, 0) DESC
        ) AS rank
    FROM store_names s
    JOIN item_store_sales iss
        ON iss.ss_store_id = s.s_store_id
    LEFT JOIN item_web_sales iws
        ON iws.i_item_id = iss.i_item_id
    LEFT JOIN item_ratings ir
        ON ir.i_item_id = iss.i_item_id
    WHERE iss.i_category_name = 'Electronics'
) t
WHERE t.rank <= 3
ORDER BY t.store_name, t.total_revenue DESC
