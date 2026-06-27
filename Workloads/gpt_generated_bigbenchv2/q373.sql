WITH store_sales_agg AS (
    SELECT
        ss.ss_store_id AS s_store_id,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue,
        COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers,
        COUNT(DISTINCT ss.ss_transaction_id) AS total_transactions
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
    GROUP BY ss.ss_store_id
),
store_items AS (
    SELECT DISTINCT
        ss.ss_store_id AS s_store_id,
        ss.ss_item_id AS i_item_id
    FROM store_sales ss
),
item_review_agg AS (
    SELECT
        pr.pr_item_id AS i_item_id,
        AVG(pr.pr_rating) AS avg_rating,
        COUNT(pr.pr_review_id) AS review_count
    FROM product_reviews pr
    GROUP BY pr.pr_item_id
),
store_rating_agg AS (
    SELECT
        si.s_store_id,
        AVG(ir.avg_rating) AS avg_rating,
        SUM(ir.review_count) AS total_review_count
    FROM store_items si
    JOIN item_review_agg ir ON ir.i_item_id = si.i_item_id
    GROUP BY si.s_store_id
)
SELECT
    s.s_store_id,
    s.s_store_name,
    COALESCE(ssa.total_quantity, 0) AS total_quantity,
    COALESCE(ssa.total_revenue, 0) AS total_revenue,
    CASE WHEN COALESCE(ssa.total_quantity, 0) > 0 THEN ssa.total_revenue / ssa.total_quantity ELSE NULL END AS avg_item_price,
    COALESCE(ssa.distinct_customers, 0) AS distinct_customers,
    COALESCE(ssa.total_transactions, 0) AS total_transactions,
    sra.avg_rating,
    COALESCE(sra.total_review_count, 0) AS total_review_count
FROM stores s
LEFT JOIN store_sales_agg ssa ON ssa.s_store_id = s.s_store_id
LEFT JOIN store_rating_agg sra ON sra.s_store_id = s.s_store_id
ORDER BY s.s_store_id
