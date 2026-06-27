WITH
    store_category_sales AS (
        SELECT
            ss.ss_store_id,
            i.i_category_id,
            i.i_category_name,
            sum(ss.ss_quantity * i.i_price) AS total_revenue,
            count(DISTINCT ss.ss_customer_id) AS distinct_customers
        FROM store_sales ss
        JOIN items i
            ON ss.ss_item_id = i.i_item_id
        GROUP BY ss.ss_store_id, i.i_category_id, i.i_category_name
    ),
    category_ratings AS (
        SELECT
            i.i_category_id,
            i.i_category_name,
            avg(pr.pr_rating) AS avg_rating
        FROM product_reviews pr
        JOIN items i
            ON pr.pr_item_id = i.i_item_id
        GROUP BY i.i_category_id, i.i_category_name
    ),
    store_category_combined AS (
        SELECT
            s.s_store_name,
            scs.i_category_name,
            scs.total_revenue,
            scs.distinct_customers,
            cr.avg_rating
        FROM store_category_sales scs
        JOIN stores s
            ON scs.ss_store_id = s.s_store_id
        LEFT JOIN category_ratings cr
            ON scs.i_category_id = cr.i_category_id
    ),
    store_category_ranked AS (
        SELECT
            scc.*, 
            row_number() OVER (PARTITION BY scc.s_store_name ORDER BY scc.total_revenue DESC) AS category_rank
        FROM store_category_combined scc
    )
SELECT
    s_store_name,
    i_category_name,
    total_revenue,
    distinct_customers,
    avg_rating,
    category_rank
FROM store_category_ranked
WHERE category_rank <= 5
ORDER BY s_store_name, total_revenue DESC
