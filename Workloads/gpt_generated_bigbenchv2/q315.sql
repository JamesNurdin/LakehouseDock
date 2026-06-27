WITH sales_with_revenue AS (
    SELECT
        ws.ws_transaction_id,
        ws.ws_customer_id,
        ws.ws_item_id,
        ws.ws_quantity,
        i.i_name,
        i.i_category_id,
        i.i_category_name,
        i.i_price,
        i.i_comp_price,
        ws.ws_quantity * i.i_price AS revenue,
        i.i_comp_price - i.i_price AS price_diff,
        (i.i_comp_price - i.i_price) / i.i_comp_price AS discount_ratio
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
),
category_agg AS (
    SELECT
        i_category_id,
        i_category_name,
        COUNT(DISTINCT ws_item_id) AS distinct_items_sold,
        COUNT(DISTINCT ws_customer_id) AS distinct_customers,
        SUM(ws_quantity) AS total_quantity,
        SUM(revenue) AS total_revenue,
        AVG(i_price) AS avg_list_price,
        AVG(i_comp_price) AS avg_comp_price,
        AVG(discount_ratio) AS avg_discount_ratio
    FROM sales_with_revenue
    GROUP BY i_category_id, i_category_name
)
SELECT
    i_category_id,
    i_category_name,
    distinct_items_sold,
    distinct_customers,
    total_quantity,
    total_revenue,
    avg_list_price,
    avg_comp_price,
    avg_discount_ratio,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
FROM category_agg
ORDER BY revenue_rank
LIMIT 10
