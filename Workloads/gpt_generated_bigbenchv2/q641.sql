WITH store_sales_agg AS (
    SELECT i.i_category_id,
           i.i_category_name,
           SUM(ss.ss_quantity) AS total_store_quantity,
           SUM(ss.ss_quantity * i.i_price) AS total_store_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
web_sales_agg AS (
    SELECT i.i_category_id,
           i.i_category_name,
           SUM(ws.ws_quantity) AS total_web_quantity,
           SUM(ws.ws_quantity * i.i_price) AS total_web_revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
),
reviews_agg AS (
    SELECT i.i_category_id,
           i.i_category_name,
           AVG(pr.pr_rating) AS avg_rating,
           AVG(i.i_price) AS avg_price,
           AVG(i.i_comp_price) AS avg_comp_price,
           AVG(i.i_price - i.i_comp_price) AS avg_price_diff
    FROM product_reviews pr
    JOIN items i ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    COALESCE(s.i_category_id, w.i_category_id, r.i_category_id) AS i_category_id,
    COALESCE(s.i_category_name, w.i_category_name, r.i_category_name) AS i_category_name,
    COALESCE(s.total_store_quantity, 0) AS total_store_quantity,
    COALESCE(s.total_store_revenue, 0) AS total_store_revenue,
    COALESCE(w.total_web_quantity, 0) AS total_web_quantity,
    COALESCE(w.total_web_revenue, 0) AS total_web_revenue,
    COALESCE(r.avg_rating, 0) AS avg_rating,
    COALESCE(r.avg_price, 0) AS avg_price,
    COALESCE(r.avg_comp_price, 0) AS avg_comp_price,
    COALESCE(r.avg_price_diff, 0) AS avg_price_diff,
    RANK() OVER (ORDER BY (COALESCE(s.total_store_quantity, 0) + COALESCE(w.total_web_quantity, 0)) DESC) AS category_rank
FROM store_sales_agg s
FULL OUTER JOIN web_sales_agg w
    ON s.i_category_id = w.i_category_id
   AND s.i_category_name = w.i_category_name
FULL OUTER JOIN reviews_agg r
    ON COALESCE(s.i_category_id, w.i_category_id) = r.i_category_id
   AND COALESCE(s.i_category_name, w.i_category_name) = r.i_category_name
ORDER BY category_rank
