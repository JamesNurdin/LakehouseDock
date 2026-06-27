WITH
    store_sales_agg AS (
        SELECT
            ss.ss_customer_id AS customer_id,
            i.i_category_id   AS category_id,
            i.i_category_name AS category_name,
            SUM(ss.ss_quantity)                         AS store_qty,
            SUM(ss.ss_quantity * i.i_price)             AS store_revenue
        FROM store_sales ss
        JOIN items i ON ss.ss_item_id = i.i_item_id
        GROUP BY ss.ss_customer_id, i.i_category_id, i.i_category_name
    ),
    web_sales_agg AS (
        SELECT
            ws.ws_customer_id AS customer_id,
            i.i_category_id   AS category_id,
            i.i_category_name AS category_name,
            SUM(ws.ws_quantity)                         AS web_qty,
            SUM(ws.ws_quantity * i.i_price)             AS web_revenue
        FROM web_sales ws
        JOIN items i ON ws.ws_item_id = i.i_item_id
        GROUP BY ws.ws_customer_id, i.i_category_id, i.i_category_name
    ),
    combined_sales AS (
        SELECT
            COALESCE(st.customer_id, wb.customer_id)                     AS customer_id,
            COALESCE(st.category_id, wb.category_id)                     AS category_id,
            COALESCE(st.category_name, wb.category_name)                 AS category_name,
            COALESCE(st.store_qty, 0) + COALESCE(wb.web_qty, 0)           AS total_qty,
            COALESCE(st.store_revenue, 0) + COALESCE(wb.web_revenue, 0)   AS total_revenue,
            COALESCE(st.store_qty, 0)                                    AS store_qty,
            COALESCE(st.store_revenue, 0)                                AS store_revenue,
            COALESCE(wb.web_qty, 0)                                      AS web_qty,
            COALESCE(wb.web_revenue, 0)                                  AS web_revenue
        FROM store_sales_agg st
        FULL OUTER JOIN web_sales_agg wb
            ON st.customer_id = wb.customer_id
            AND st.category_id = wb.category_id
    )
SELECT
    c.c_customer_id,
    c.c_name,
    cs.category_id,
    cs.category_name,
    cs.total_qty,
    cs.total_revenue,
    cs.store_qty,
    cs.store_revenue,
    cs.web_qty,
    cs.web_revenue,
    ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY cs.total_revenue DESC) AS revenue_rank
FROM combined_sales cs
JOIN customers c ON c.c_customer_id = cs.customer_id
WHERE cs.total_revenue > 1000
ORDER BY cs.total_revenue DESC
LIMIT 100
