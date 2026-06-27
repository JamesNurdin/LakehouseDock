WITH sales_per_item AS (
    SELECT
        ws.ws_item_id,
        SUM(ws.ws_quantity) AS total_quantity,
        MAX(i.i_price) AS item_price,
        MAX(i.i_comp_price) AS competitor_price,
        SUM(ws.ws_quantity * i.i_price) AS total_revenue,
        COUNT(DISTINCT ws.ws_transaction_id) AS transaction_count
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY ws.ws_item_id
)
SELECT
    i.i_category_id,
    i.i_category_name,
    i.i_item_id,
    i.i_name,
    s.total_quantity,
    s.item_price,
    s.competitor_price,
    s.total_revenue,
    s.transaction_count,
    (s.item_price - s.competitor_price) * s.total_quantity AS total_margin,
    ROW_NUMBER() OVER (PARTITION BY i.i_category_id ORDER BY s.total_revenue DESC) AS revenue_rank_in_category
FROM sales_per_item s
JOIN items i
    ON s.ws_item_id = i.i_item_id
ORDER BY i.i_category_id, revenue_rank_in_category
