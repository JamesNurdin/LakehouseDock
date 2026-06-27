WITH all_sales AS (
    SELECT
        ss.ss_customer_id AS c_customer_id,
        c.c_name AS c_name,
        'store' AS channel,
        ss.ss_quantity * i.i_price AS revenue,
        ss.ss_quantity AS quantity,
        ss.ss_item_id AS item_id
    FROM store_sales ss
    JOIN customers c ON ss.ss_customer_id = c.c_customer_id
    JOIN items i ON ss.ss_item_id = i.i_item_id
    UNION ALL
    SELECT
        ws.ws_customer_id AS c_customer_id,
        c.c_name AS c_name,
        'web' AS channel,
        ws.ws_quantity * i.i_price AS revenue,
        ws.ws_quantity AS quantity,
        ws.ws_item_id AS item_id
    FROM web_sales ws
    JOIN customers c ON ws.ws_customer_id = c.c_customer_id
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
customer_agg AS (
    SELECT
        c_customer_id,
        c_name,
        SUM(CASE WHEN channel = 'store' THEN revenue ELSE 0 END) AS store_revenue,
        SUM(CASE WHEN channel = 'web'   THEN revenue ELSE 0 END) AS web_revenue,
        SUM(CASE WHEN channel = 'store' THEN quantity ELSE 0 END) AS store_quantity,
        SUM(CASE WHEN channel = 'web'   THEN quantity ELSE 0 END) AS web_quantity,
        COUNT(DISTINCT CASE WHEN channel = 'store' THEN item_id END) AS store_distinct_items,
        COUNT(DISTINCT CASE WHEN channel = 'web'   THEN item_id END) AS web_distinct_items,
        COUNT(DISTINCT item_id) AS total_distinct_items
    FROM all_sales
    GROUP BY c_customer_id, c_name
),
customer_totals AS (
    SELECT
        c_customer_id,
        c_name,
        store_revenue + web_revenue AS total_revenue,
        store_quantity + web_quantity AS total_quantity,
        total_distinct_items,
        CASE
            WHEN (store_quantity + web_quantity) = 0 THEN 0
            ELSE (store_revenue + web_revenue) / (store_quantity + web_quantity)
        END AS avg_price_per_item,
        store_revenue,
        web_revenue,
        store_quantity,
        web_quantity,
        store_distinct_items,
        web_distinct_items
    FROM customer_agg
)
SELECT
    c_customer_id,
    c_name,
    total_revenue,
    total_quantity,
    total_distinct_items,
    avg_price_per_item,
    store_revenue,
    web_revenue,
    store_quantity,
    web_quantity,
    store_distinct_items,
    web_distinct_items,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM customer_totals
ORDER BY total_revenue DESC
LIMIT 10
