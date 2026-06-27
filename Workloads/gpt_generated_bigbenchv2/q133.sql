WITH store_agg AS (
    SELECT
        c.c_customer_id,
        c.c_name,
        i.i_category_id,
        i.i_category_name,
        SUM(ss.ss_quantity) AS store_qty,
        SUM(ss.ss_quantity * i.i_price) AS store_rev
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    JOIN stores s ON ss.ss_store_id = s.s_store_id
    GROUP BY
        c.c_customer_id,
        c.c_name,
        i.i_category_id,
        i.i_category_name
),
web_agg AS (
    SELECT
        c.c_customer_id,
        c.c_name,
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS web_qty,
        SUM(ws.ws_quantity * i.i_price) AS web_rev
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
    GROUP BY
        c.c_customer_id,
        c.c_name,
        i.i_category_id,
        i.i_category_name
)
SELECT
    COALESCE(store_agg.c_customer_id, web_agg.c_customer_id) AS c_customer_id,
    COALESCE(store_agg.c_name, web_agg.c_name) AS c_name,
    COALESCE(store_agg.i_category_id, web_agg.i_category_id) AS i_category_id,
    COALESCE(store_agg.i_category_name, web_agg.i_category_name) AS i_category_name,
    COALESCE(store_agg.store_qty, 0) AS store_quantity,
    COALESCE(web_agg.web_qty, 0) AS web_quantity,
    COALESCE(store_agg.store_rev, 0) AS store_revenue,
    COALESCE(web_agg.web_rev, 0) AS web_revenue,
    COALESCE(store_agg.store_qty, 0) + COALESCE(web_agg.web_qty, 0) AS total_quantity,
    COALESCE(store_agg.store_rev, 0) + COALESCE(web_agg.web_rev, 0) AS total_revenue
FROM store_agg
FULL OUTER JOIN web_agg
    ON store_agg.c_customer_id = web_agg.c_customer_id
    AND store_agg.i_category_id = web_agg.i_category_id
ORDER BY total_revenue DESC
LIMIT 100
