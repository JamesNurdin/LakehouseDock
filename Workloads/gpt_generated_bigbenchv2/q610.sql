WITH store_sales_enriched AS (
    SELECT ss.ss_item_id,
           i.i_category,
           ss.ss_quantity AS quantity,
           ss.ss_quantity * i.i_price AS revenue
    FROM store_sales ss
    JOIN items i ON ss.ss_item_id = i.i_item_id
),
web_sales_enriched AS (
    SELECT ws.ws_item_id AS ss_item_id,
           i.i_category,
           ws.ws_quantity AS quantity,
           ws.ws_quantity * i.i_price AS revenue
    FROM web_sales ws
    JOIN items i ON ws.ws_item_id = i.i_item_id
),
combined_sales AS (
    SELECT * FROM store_sales_enriched
    UNION ALL
    SELECT * FROM web_sales_enriched
)
SELECT cs.i_category,
       SUM(cs.quantity) AS total_quantity,
       SUM(cs.revenue) AS total_revenue
FROM combined_sales cs
GROUP BY cs.i_category
ORDER BY total_revenue DESC
LIMIT 10
