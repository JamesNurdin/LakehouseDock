WITH store_category_sales AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        i.i_category,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY s.s_store_id, s.s_store_name, i.i_category
),
ranked_sales AS (
    SELECT
        scs.s_store_id,
        scs.s_store_name,
        scs.i_category,
        scs.total_quantity,
        scs.total_revenue,
        ROW_NUMBER() OVER (PARTITION BY scs.s_store_id ORDER BY scs.total_revenue DESC) AS category_rank
    FROM store_category_sales scs
)
SELECT
    rs.s_store_id,
    rs.s_store_name,
    rs.i_category,
    rs.total_quantity,
    rs.total_revenue,
    rs.category_rank
FROM ranked_sales rs
WHERE rs.category_rank <= 3
ORDER BY rs.s_store_id, rs.category_rank
