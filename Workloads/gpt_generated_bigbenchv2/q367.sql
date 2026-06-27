WITH sales_with_price AS (
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
        i.i_class_id,
        ws.ws_quantity * i.i_price AS revenue,
        ws.ws_quantity * (i.i_price - i.i_comp_price) AS profit
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
),
category_agg AS (
    SELECT
        i_category_name,
        i_class_id,
        sum(revenue) AS total_revenue,
        sum(profit) AS total_profit,
        sum(ws_quantity) AS total_quantity,
        count(DISTINCT ws_item_id) AS distinct_items_sold,
        avg(i_price) AS avg_item_price
    FROM sales_with_price
    GROUP BY i_category_name, i_class_id
)
SELECT
    i_category_name,
    i_class_id,
    total_revenue,
    total_profit,
    total_quantity,
    distinct_items_sold,
    avg_item_price,
    total_revenue * 100.0 / sum(total_revenue) OVER () AS revenue_pct_of_total
FROM category_agg
ORDER BY total_revenue DESC
