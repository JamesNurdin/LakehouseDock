WITH unified_sales AS (
    SELECT ss_customer_id AS customer_id,
           ss_item_id   AS item_id,
           ss_quantity  AS quantity,
           'store'      AS channel
    FROM store_sales
    UNION ALL
    SELECT ws_customer_id AS customer_id,
           ws_item_id   AS item_id,
           ws_quantity  AS quantity,
           'web'        AS channel
    FROM web_sales
)
SELECT
    c.c_customer_id,
    c.c_name,
    i.i_category_id,
    i.i_category_name,
    SUM(us.quantity) AS total_quantity,
    SUM(us.quantity * i.i_price) AS total_revenue,
    SUM(CASE WHEN us.channel = 'store' THEN us.quantity ELSE 0 END) AS store_quantity,
    SUM(CASE WHEN us.channel = 'web'   THEN us.quantity ELSE 0 END) AS web_quantity
FROM unified_sales us
JOIN customers c ON us.customer_id = c.c_customer_id
JOIN items i      ON us.item_id = i.i_item_id
GROUP BY
    c.c_customer_id,
    c.c_name,
    i.i_category_id,
    i.i_category_name
HAVING SUM(us.quantity * i.i_price) > 1000
ORDER BY total_revenue DESC
LIMIT 50
