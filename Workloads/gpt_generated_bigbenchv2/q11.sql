WITH sales_items AS (
    SELECT
        ss.ss_store_id,
        i.i_category_id,
        i.i_category_name,
        ss.ss_quantity,
        i.i_price,
        i.i_comp_price
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
),
category_store_revenue AS (
    SELECT
        si.i_category_id,
        si.i_category_name,
        si.ss_store_id,
        SUM(si.ss_quantity) AS total_quantity,
        SUM(si.i_price * si.ss_quantity) AS total_revenue,
        AVG(si.i_price - si.i_comp_price) AS avg_price_gap
    FROM sales_items si
    GROUP BY si.i_category_id, si.i_category_name, si.ss_store_id
)
SELECT
    csr.i_category_id,
    csr.i_category_name,
    csr.ss_store_id,
    csr.total_quantity,
    csr.total_revenue,
    csr.avg_price_gap,
    RANK() OVER (PARTITION BY csr.i_category_id ORDER BY csr.total_revenue DESC) AS revenue_rank
FROM category_store_revenue csr
WHERE csr.total_quantity > 0
ORDER BY csr.i_category_id, revenue_rank
LIMIT 20
