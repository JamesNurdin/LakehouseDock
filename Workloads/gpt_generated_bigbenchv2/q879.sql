WITH
    store_sales_agg AS (
        SELECT
            ss.ss_item_id AS i_item_id,
            SUM(ss.ss_quantity) AS store_quantity,
            SUM(ss.ss_quantity * i.i_price) AS store_revenue
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        GROUP BY ss.ss_item_id
    ),
    web_sales_agg AS (
        SELECT
            ws.ws_item_id AS i_item_id,
            SUM(ws.ws_quantity) AS web_quantity,
            SUM(ws.ws_quantity * i.i_price) AS web_revenue
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        GROUP BY ws.ws_item_id
    ),
    rating_agg AS (
        SELECT
            pr.pr_item_id AS i_item_id,
            AVG(pr.pr_rating) AS avg_rating,
            COUNT(*) AS review_count
        FROM product_reviews pr
        GROUP BY pr.pr_item_id
    ),
    item_metrics AS (
        SELECT
            i.i_item_id,
            i.i_name,
            i.i_category_id,
            i.i_category_name,
            COALESCE(ss.store_quantity, 0) AS store_quantity,
            COALESCE(ss.store_revenue, 0) AS store_revenue,
            COALESCE(ws.web_quantity, 0) AS web_quantity,
            COALESCE(ws.web_revenue, 0) AS web_revenue,
            COALESCE(r.avg_rating, 0) AS avg_rating,
            COALESCE(r.review_count, 0) AS review_count,
            (COALESCE(ss.store_quantity, 0) + COALESCE(ws.web_quantity, 0)) AS total_quantity,
            (COALESCE(ss.store_revenue, 0) + COALESCE(ws.web_revenue, 0)) AS total_revenue
        FROM items i
        LEFT JOIN store_sales_agg ss ON ss.i_item_id = i.i_item_id
        LEFT JOIN web_sales_agg ws ON ws.i_item_id = i.i_item_id
        LEFT JOIN rating_agg r ON r.i_item_id = i.i_item_id
    ),
    category_aggregates AS (
        SELECT
            i_category_id,
            i_category_name,
            SUM(total_quantity) AS category_total_quantity,
            SUM(total_revenue) AS category_total_revenue,
            AVG(avg_rating) AS category_avg_rating
        FROM item_metrics
        GROUP BY i_category_id, i_category_name
    ),
    final_with_rank AS (
        SELECT
            im.i_category_id,
            im.i_category_name,
            im.i_item_id,
            im.i_name,
            im.total_quantity,
            im.total_revenue,
            im.avg_rating,
            ca.category_total_quantity,
            ca.category_total_revenue,
            ca.category_avg_rating,
            rank() OVER (PARTITION BY im.i_category_id ORDER BY im.total_revenue DESC) AS revenue_rank
        FROM item_metrics im
        JOIN category_aggregates ca
            ON im.i_category_id = ca.i_category_id
            AND im.i_category_name = ca.i_category_name
    )
SELECT
    i_category_id,
    i_category_name,
    i_item_id,
    i_name,
    total_quantity,
    total_revenue,
    avg_rating,
    category_total_quantity,
    category_total_revenue,
    category_avg_rating,
    revenue_rank
FROM final_with_rank
WHERE revenue_rank <= 5
ORDER BY i_category_id, revenue_rank
