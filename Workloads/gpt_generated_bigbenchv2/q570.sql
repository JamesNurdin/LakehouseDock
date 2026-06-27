WITH
    store_sales_agg AS (
        SELECT
            ss.ss_store_id AS ss_store_id,
            s.s_store_name AS s_store_name,
            i.i_item_id AS i_item_id,
            i.i_name AS i_name,
            i.i_category_id AS i_category_id,
            i.i_category_name AS i_category_name,
            SUM(ss.ss_quantity) AS total_quantity,
            SUM(ss.ss_quantity * i.i_price) AS total_revenue,
            COUNT(DISTINCT ss.ss_customer_id) AS distinct_customers
        FROM store_sales ss
        JOIN stores s ON ss.ss_store_id = s.s_store_id
        JOIN items i ON ss.ss_item_id = i.i_item_id
        GROUP BY
            ss.ss_store_id,
            s.s_store_name,
            i.i_item_id,
            i.i_name,
            i.i_category_id,
            i.i_category_name
    ),
    web_sales_agg AS (
        SELECT
            CAST(NULL AS BIGINT) AS ss_store_id,
            CAST('Online' AS VARCHAR) AS s_store_name,
            i.i_item_id AS i_item_id,
            i.i_name AS i_name,
            i.i_category_id AS i_category_id,
            i.i_category_name AS i_category_name,
            SUM(ws.ws_quantity) AS total_quantity,
            SUM(ws.ws_quantity * i.i_price) AS total_revenue,
            COUNT(DISTINCT ws.ws_customer_id) AS distinct_customers
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        GROUP BY
            i.i_item_id,
            i.i_name,
            i.i_category_id,
            i.i_category_name
    ),
    sales_combined AS (
        SELECT
            ss_store_id,
            s_store_name,
            i_item_id,
            i_name,
            i_category_id,
            i_category_name,
            total_quantity,
            total_revenue,
            distinct_customers
        FROM store_sales_agg
        UNION ALL
        SELECT
            ss_store_id,
            s_store_name,
            i_item_id,
            i_name,
            i_category_id,
            i_category_name,
            total_quantity,
            total_revenue,
            distinct_customers
        FROM web_sales_agg
    ),
    item_ratings AS (
        SELECT
            pr.pr_item_id AS pr_item_id,
            AVG(pr.pr_rating) AS avg_rating,
            COUNT(*) AS rating_count
        FROM product_reviews pr
        GROUP BY pr.pr_item_id
    ),
    sales_by_item AS (
        SELECT
            sc.s_store_name AS s_store_name,
            sc.i_item_id AS i_item_id,
            sc.i_name AS i_name,
            sc.i_category_name AS i_category_name,
            SUM(sc.total_quantity) AS total_quantity,
            SUM(sc.total_revenue) AS total_revenue
        FROM sales_combined sc
        GROUP BY
            sc.s_store_name,
            sc.i_item_id,
            sc.i_name,
            sc.i_category_name
    ),
    sales_with_rating AS (
        SELECT
            sbi.s_store_name AS s_store_name,
            sbi.i_item_id AS i_item_id,
            sbi.i_name AS i_name,
            sbi.i_category_name AS i_category_name,
            sbi.total_quantity AS total_quantity,
            sbi.total_revenue AS total_revenue,
            ir.avg_rating AS avg_rating,
            ir.rating_count AS rating_count
        FROM sales_by_item sbi
        LEFT JOIN item_ratings ir ON sbi.i_item_id = ir.pr_item_id
    ),
    ranked_sales AS (
        SELECT
            swr.s_store_name AS s_store_name,
            swr.i_item_id AS i_item_id,
            swr.i_name AS i_name,
            swr.i_category_name AS i_category_name,
            swr.total_quantity AS total_quantity,
            swr.total_revenue AS total_revenue,
            swr.avg_rating AS avg_rating,
            swr.rating_count AS rating_count,
            ROW_NUMBER() OVER (PARTITION BY swr.s_store_name ORDER BY swr.total_revenue DESC) AS revenue_rank
        FROM sales_with_rating swr
    )
SELECT
    rs.s_store_name,
    rs.i_name,
    rs.i_category_name,
    rs.total_quantity,
    rs.total_revenue,
    rs.avg_rating,
    rs.rating_count
FROM ranked_sales rs
WHERE rs.revenue_rank <= 3
ORDER BY rs.s_store_name, rs.revenue_rank
