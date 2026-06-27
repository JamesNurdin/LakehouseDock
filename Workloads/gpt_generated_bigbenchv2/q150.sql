WITH store_sales_agg AS (
    SELECT
        ss.ss_store_id,
        s.s_store_name,
        COUNT(DISTINCT ss.ss_transaction_id) AS transaction_count,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_quantity * i.i_price) AS total_revenue,
        AVG(i.i_price) AS avg_item_price
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    JOIN stores s
        ON ss.ss_store_id = s.s_store_id
    GROUP BY ss.ss_store_id, s.s_store_name
),
store_reviews_agg AS (
    SELECT
        ss.ss_store_id,
        AVG(pr.pr_rating) AS avg_review_rating,
        COUNT(DISTINCT pr.pr_review_id) AS review_count
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id
    JOIN product_reviews pr
        ON pr.pr_item_id = i.i_item_id
    GROUP BY ss.ss_store_id
)
SELECT
    ssa.ss_store_id,
    ssa.s_store_name,
    ssa.transaction_count,
    ssa.total_quantity,
    ssa.total_revenue,
    ssa.avg_item_price,
    sra.avg_review_rating,
    sra.review_count
FROM store_sales_agg ssa
LEFT JOIN store_reviews_agg sra
    ON ssa.ss_store_id = sra.ss_store_id
ORDER BY ssa.total_revenue DESC
LIMIT 10
