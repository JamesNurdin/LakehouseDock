WITH item_avg_rating AS (
    SELECT
        i.i_item_id,
        AVG(pr.pr_rating) AS avg_rating
    FROM product_reviews pr
    JOIN items i
        ON pr.pr_item_id = i.i_item_id
    GROUP BY i.i_item_id
),
store_category_sales AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    GROUP BY s.s_store_id, s.s_store_name, i.i_category_id, i.i_category_name
),
store_category_rating AS (
    SELECT
        s.s_store_id,
        i.i_category_id,
        AVG(ar.avg_rating) AS avg_item_rating
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    JOIN item_avg_rating ar
        ON i.i_item_id = ar.i_item_id
    GROUP BY s.s_store_id, i.i_category_id
)
SELECT
    scs.s_store_name,
    scs.i_category_name,
    scs.total_quantity,
    scs.total_revenue,
    scr.avg_item_rating,
    RANK() OVER (PARTITION BY scs.i_category_name ORDER BY scs.total_revenue DESC) AS revenue_rank
FROM store_category_sales scs
LEFT JOIN store_category_rating scr
    ON scs.s_store_id = scr.s_store_id
    AND scs.i_category_id = scr.i_category_id
ORDER BY scs.i_category_name, revenue_rank
LIMIT 50
