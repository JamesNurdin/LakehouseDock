/*
  Analytical query: For each store and product category, compute the total quantity sold in‑store,
  total quantity sold online, distinct customer counts, and average item ratings.  Also rank the
  categories per store by in‑store quantity.
*/
WITH store_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS total_store_quantity,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_store_customers,
        AVG(pr.pr_rating) AS avg_store_item_rating
    FROM store_sales ss
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    LEFT JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
    GROUP BY s.s_store_id, s.s_store_name, i.i_category_id, i.i_category_name
),
web_agg AS (
    SELECT
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS total_online_quantity,
        COUNT(DISTINCT ws.ws_customer_id) AS distinct_online_customers,
        AVG(pr.pr_rating) AS avg_online_item_rating
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
    LEFT JOIN product_reviews pr ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_category_id, i.i_category_name
)
SELECT
    sa.s_store_name,
    sa.i_category_name,
    sa.total_store_quantity,
    wa.total_online_quantity,
    sa.distinct_store_customers,
    wa.distinct_online_customers,
    COALESCE(sa.avg_store_item_rating, 0) AS avg_store_item_rating,
    COALESCE(wa.avg_online_item_rating, 0) AS avg_online_item_rating,
    ROW_NUMBER() OVER (PARTITION BY sa.s_store_name ORDER BY sa.total_store_quantity DESC) AS store_category_rank
FROM store_agg sa
LEFT JOIN web_agg wa
    ON sa.i_category_id = wa.i_category_id
ORDER BY sa.s_store_name, store_category_rank
