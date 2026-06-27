WITH item_ratings AS (
    SELECT
        pr.pr_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(*) AS rating_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
store_sales_with_items AS (
    SELECT
        ss.ss_store_id,
        ss.ss_customer_id,
        ss.ss_quantity,
        i.i_price,
        i.i_item_id,
        s.s_store_name
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
),
store_sales_agg AS (
    SELECT
        ssi.ss_store_id,
        ssi.s_store_name,
        SUM(ssi.ss_quantity) AS total_quantity,
        SUM(ssi.ss_quantity * ssi.i_price) AS total_revenue,
        COUNT(DISTINCT ssi.ss_customer_id) AS distinct_customers
    FROM store_sales_with_items ssi
    GROUP BY ssi.ss_store_id, ssi.s_store_name
),
store_item_ratings AS (
    SELECT
        ssi.ss_store_id,
        AVG(ir.avg_rating) AS store_avg_item_rating,
        SUM(ir.rating_count) AS total_rating_count
    FROM store_sales_with_items ssi
    JOIN item_ratings ir ON ssi.i_item_id = ir.pr_item_id
    GROUP BY ssi.ss_store_id
),
web_sales_agg AS (
    SELECT
        ws.ws_item_id,
        SUM(ws.ws_quantity) AS total_web_quantity
    FROM web_sales ws
    GROUP BY ws.ws_item_id
),
store_web_sales AS (
    SELECT
        ssi.ss_store_id,
        SUM(wsa.total_web_quantity) AS total_web_quantity_for_store_items
    FROM store_sales_with_items ssi
    JOIN web_sales_agg wsa ON ssi.i_item_id = wsa.ws_item_id
    GROUP BY ssi.ss_store_id
)
SELECT
    ssa.ss_store_id,
    ssa.s_store_name,
    ssa.total_quantity,
    ssa.total_revenue,
    ssa.distinct_customers,
    sir.store_avg_item_rating,
    sir.total_rating_count,
    sws.total_web_quantity_for_store_items
FROM store_sales_agg ssa
LEFT JOIN store_item_ratings sir ON ssa.ss_store_id = sir.ss_store_id
LEFT JOIN store_web_sales sws ON ssa.ss_store_id = sws.ss_store_id
ORDER BY ssa.total_revenue DESC
LIMIT 10
