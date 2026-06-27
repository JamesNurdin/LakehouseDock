WITH sales_by_store_item AS (
    SELECT
        ss.ss_store_id,
        ss.ss_item_id,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue,
        SUM(ss.ss_quantity * i.i_comp_price) AS total_comp_revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id, ss.ss_item_id
),
ranked_items AS (
    SELECT
        sbsi.ss_store_id,
        sbsi.ss_item_id,
        sbsi.total_quantity,
        sbsi.total_revenue,
        sbsi.total_comp_revenue,
        (sbsi.total_revenue - sbsi.total_comp_revenue) AS revenue_diff,
        ROW_NUMBER() OVER (
            PARTITION BY sbsi.ss_store_id
            ORDER BY (sbsi.total_revenue - sbsi.total_comp_revenue) DESC
        ) AS rank
    FROM sales_by_store_item sbsi
)
SELECT
    s.s_store_name,
    i.i_category_name,
    i.i_name,
    ri.total_quantity,
    ri.total_revenue,
    ri.total_comp_revenue,
    ri.revenue_diff,
    ri.total_revenue / NULLIF(ri.total_quantity, 0) AS avg_price_sold,
    ri.rank
FROM ranked_items ri
JOIN stores s ON ri.ss_store_id = s.s_store_id
JOIN items i ON ri.ss_item_id = i.i_item_id
WHERE ri.rank <= 5
ORDER BY s.s_store_name, ri.rank
