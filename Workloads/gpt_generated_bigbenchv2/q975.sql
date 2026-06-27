WITH store_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS store_qty,
        COUNT(DISTINCT ss.ss_customer_id) AS store_customer_cnt
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
web_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS web_qty,
        COUNT(DISTINCT ws.ws_customer_id) AS web_customer_cnt
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
review_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS review_cnt
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
price_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        AVG(i.i_price) AS avg_price
    FROM items i
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    COALESCE(s.i_category_id, w.i_category_id, r.i_category_id, p.i_category_id) AS category_id,
    COALESCE(s.i_category_name, w.i_category_name, r.i_category_name, p.i_category_name) AS category_name,
    COALESCE(s.store_qty, 0) + COALESCE(w.web_qty, 0) AS total_qty,
    COALESCE(s.store_qty, 0) AS store_qty,
    COALESCE(w.web_qty, 0) AS web_qty,
    COALESCE(s.store_customer_cnt, 0) + COALESCE(w.web_customer_cnt, 0) AS distinct_customers,
    r.avg_rating,
    r.review_cnt,
    p.avg_price,
    RANK() OVER (ORDER BY COALESCE(s.store_qty, 0) + COALESCE(w.web_qty, 0) DESC) AS category_rank
FROM store_agg s
FULL OUTER JOIN web_agg w
    ON s.i_category_id = w.i_category_id
FULL OUTER JOIN review_agg r
    ON COALESCE(s.i_category_id, w.i_category_id) = r.i_category_id
FULL OUTER JOIN price_agg p
    ON COALESCE(s.i_category_id, w.i_category_id, r.i_category_id) = p.i_category_id
ORDER BY total_qty DESC
LIMIT 20
