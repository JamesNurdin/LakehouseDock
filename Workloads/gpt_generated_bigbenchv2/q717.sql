WITH
    store_agg AS (
        SELECT
            c.c_customer_id,
            c.c_name,
            i.i_category_id,
            i.i_category_name,
            s.s_store_name,
            SUM(ss.ss_quantity) AS store_quantity,
            SUM(ss.ss_quantity * i.i_price) AS store_revenue
        FROM store_sales ss
        JOIN customers c ON ss.ss_customer_id = c.c_customer_id
        JOIN items i ON ss.ss_item_id = i.i_item_id
        JOIN stores s ON ss.ss_store_id = s.s_store_id
        GROUP BY
            c.c_customer_id,
            c.c_name,
            i.i_category_id,
            i.i_category_name,
            s.s_store_name
    ),
    web_agg AS (
        SELECT
            c.c_customer_id,
            c.c_name,
            i.i_category_id,
            i.i_category_name,
            SUM(ws.ws_quantity) AS web_quantity,
            SUM(ws.ws_quantity * i.i_price) AS web_revenue
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
    COALESCE(sa.c_customer_id, wa.c_customer_id) AS customer_id,
    COALESCE(sa.c_name, wa.c_name) AS customer_name,
    COALESCE(sa.i_category_id, wa.i_category_id) AS category_id,
    COALESCE(sa.i_category_name, wa.i_category_name) AS category_name,
    sa.s_store_name,
    COALESCE(sa.store_quantity, 0) AS store_quantity,
    COALESCE(sa.store_revenue, 0) AS store_revenue,
    COALESCE(wa.web_quantity, 0) AS web_quantity,
    COALESCE(wa.web_revenue, 0) AS web_revenue
FROM store_agg sa
FULL OUTER JOIN web_agg wa
    ON sa.c_customer_id = wa.c_customer_id
    AND sa.i_category_id = wa.i_category_id
ORDER BY
    store_revenue DESC,
    web_revenue DESC
LIMIT 100
