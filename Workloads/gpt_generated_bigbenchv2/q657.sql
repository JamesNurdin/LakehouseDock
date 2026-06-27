WITH
    store_sales_enriched AS (
        SELECT
            ss.ss_store_id AS store_id,
            s.s_store_name AS store_name,
            i.i_category_id AS category_id,
            i.i_category_name AS category_name,
            ss.ss_quantity AS quantity,
            ss.ss_quantity * i.i_price AS revenue
        FROM store_sales ss
        JOIN stores s ON ss.ss_store_id = s.s_store_id
        JOIN items i ON ss.ss_item_id = i.i_item_id
    ),
    web_sales_enriched AS (
        SELECT
            NULL AS store_id,
            'Online' AS store_name,
            i.i_category_id AS category_id,
            i.i_category_name AS category_name,
            ws.ws_quantity AS quantity,
            ws.ws_quantity * i.i_price AS revenue
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
    ),
    combined_sales AS (
        SELECT * FROM store_sales_enriched
        UNION ALL
        SELECT * FROM web_sales_enriched
    ),
    store_category_agg AS (
        SELECT
            store_id,
            store_name,
            category_id,
            category_name,
            SUM(quantity) AS total_quantity,
            SUM(revenue) AS total_revenue
        FROM combined_sales
        GROUP BY
            store_id,
            store_name,
            category_id,
            category_name
    ),
    ranked AS (
        SELECT
            store_id,
            store_name,
            category_id,
            category_name,
            total_quantity,
            total_revenue,
            ROW_NUMBER() OVER (PARTITION BY store_id ORDER BY total_revenue DESC) AS category_rank
        FROM store_category_agg
    )
SELECT
    store_name,
    category_name,
    total_quantity,
    total_revenue,
    category_rank
FROM ranked
WHERE category_rank <= 3
ORDER BY store_name, category_rank
