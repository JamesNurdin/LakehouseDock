WITH store_item_revenue AS (
    SELECT
        ss.ss_store_id,
        i.i_category_id,
        i.i_category_name,
        i.i_item_id,
        i.i_name,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue,
        SUM(ss.ss_quantity * i.i_comp_price) AS total_comp_revenue,
        AVG(i.i_price) AS avg_price,
        AVG(i.i_comp_price) AS avg_comp_price
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY
        ss.ss_store_id,
        i.i_category_id,
        i.i_category_name,
        i.i_item_id,
        i.i_name
),
ranked_items AS (
    SELECT
        sir.ss_store_id,
        sir.i_category_id,
        sir.i_category_name,
        sir.i_item_id,
        sir.i_name,
        sir.total_quantity,
        sir.total_revenue,
        sir.total_comp_revenue,
        sir.avg_price,
        sir.avg_comp_price,
        ROW_NUMBER() OVER (
            PARTITION BY sir.ss_store_id, sir.i_category_id
            ORDER BY sir.total_revenue DESC
        ) AS rank_in_category
    FROM store_item_revenue sir
)
SELECT
    ri.ss_store_id,
    ri.i_category_id,
    ri.i_category_name,
    ri.i_item_id,
    ri.i_name,
    ri.total_quantity,
    ri.total_revenue,
    ri.total_comp_revenue,
    ri.avg_price,
    ri.avg_comp_price,
    ri.total_revenue - ri.total_comp_revenue AS revenue_gap,
    ri.rank_in_category
FROM ranked_items ri
WHERE ri.rank_in_category <= 3
ORDER BY ri.ss_store_id, ri.i_category_id, ri.rank_in_category
