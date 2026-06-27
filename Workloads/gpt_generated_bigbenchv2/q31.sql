WITH sales_union AS (
    SELECT
        ss.ss_customer_id AS c_customer_id,
        ss.ss_quantity AS quantity,
        ss.ss_quantity * i.i_price AS revenue,
        i.i_category_name AS i_category_name
    FROM store_sales ss
    JOIN items i
        ON ss.ss_item_id = i.i_item_id

    UNION ALL

    SELECT
        ws.ws_customer_id AS c_customer_id,
        ws.ws_quantity AS quantity,
        ws.ws_quantity * i.i_price AS revenue,
        i.i_category_name AS i_category_name
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
),
agg AS (
    SELECT
        c.c_customer_id,
        c.c_name,
        su.i_category_name,
        SUM(su.quantity) AS total_quantity,
        SUM(su.revenue) AS total_revenue
    FROM sales_union su
    JOIN customers c
        ON su.c_customer_id = c.c_customer_id
    GROUP BY c.c_customer_id, c.c_name, su.i_category_name
    HAVING SUM(su.quantity) > 10
)
SELECT
    c_customer_id,
    c_name,
    i_category_name,
    total_quantity,
    total_revenue,
    total_quantity * 1.0 / SUM(total_quantity) OVER () AS pct_of_total_quantity,
    total_revenue * 1.0 / SUM(total_revenue) OVER () AS pct_of_total_revenue
FROM agg
ORDER BY total_revenue DESC
LIMIT 100
