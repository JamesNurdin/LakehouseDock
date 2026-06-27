WITH store_agg AS (
    SELECT i.i_category_id,
           i.i_category_name,
           SUM(ss.ss_quantity) AS store_quantity,
           COUNT(DISTINCT ss.ss_customer_id) AS store_customer_cnt
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
web_agg AS (
    SELECT i.i_category_id,
           i.i_category_name,
           SUM(ws.ws_quantity) AS web_quantity,
           COUNT(DISTINCT ws.ws_customer_id) AS web_customer_cnt
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
review_agg AS (
    SELECT i.i_category_id,
           i.i_category_name,
           AVG(pr.pr_rating) AS avg_rating,
           COUNT(*) AS review_cnt
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
price_agg AS (
    SELECT i.i_category_id,
           i.i_category_name,
           AVG(i.i_price) AS avg_price,
           AVG(i.i_comp_price) AS avg_comp_price
    FROM items i
    GROUP BY i.i_category_id, i.i_category_name
),
store_rank AS (
    SELECT i.i_category_id,
           i.i_category_name,
           s.s_store_name,
           SUM(ss.ss_quantity) AS store_quantity,
           ROW_NUMBER() OVER (PARTITION BY i.i_category_id ORDER BY SUM(ss.ss_quantity) DESC) AS rn
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY i.i_category_id, i.i_category_name, s.s_store_name
)
SELECT
    COALESCE(s.i_category_id, w.i_category_id, r.i_category_id, p.i_category_id) AS category_id,
    COALESCE(s.i_category_name, w.i_category_name, r.i_category_name, p.i_category_name) AS category_name,
    COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0) AS total_quantity,
    COALESCE(s.store_customer_cnt, 0) + COALESCE(w.web_customer_cnt, 0) AS total_customer_cnt,
    COALESCE(r.avg_rating, 0) AS avg_rating,
    COALESCE(r.review_cnt, 0) AS review_cnt,
    p.avg_price,
    p.avg_comp_price,
    top_store.s_store_name AS top_store_name,
    top_store.store_quantity AS top_store_quantity
FROM store_agg s
FULL OUTER JOIN web_agg w
    ON s.i_category_id = w.i_category_id
FULL OUTER JOIN review_agg r
    ON COALESCE(s.i_category_id, w.i_category_id) = r.i_category_id
FULL OUTER JOIN price_agg p
    ON COALESCE(s.i_category_id, w.i_category_id, r.i_category_id) = p.i_category_id
LEFT JOIN (
    SELECT i_category_id, s_store_name, store_quantity
    FROM store_rank
    WHERE rn = 1
) top_store
    ON COALESCE(s.i_category_id, w.i_category_id, r.i_category_id, p.i_category_id) = top_store.i_category_id
ORDER BY total_quantity DESC
LIMIT 10
