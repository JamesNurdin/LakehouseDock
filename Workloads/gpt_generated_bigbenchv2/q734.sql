WITH item_sales AS (
    SELECT
        i.i_item_id,
        i.i_name,
        i.i_category_id,
        i.i_category_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_revenue,
        AVG(i.i_price) AS avg_price,
        AVG((i.i_price - i.i_comp_price) / NULLIF(i.i_price, 0)) AS avg_discount_rate,
        COUNT(DISTINCT ws.ws_customer_id) AS distinct_customers,
        MIN(ws.ws_ts) AS first_sale_ts,
        MAX(ws.ws_ts) AS last_sale_ts
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY i.i_item_id, i.i_name, i.i_category_id, i.i_category_name
),
ranked_sales AS (
    SELECT
        isales.*,
        ROW_NUMBER() OVER (PARTITION BY isales.i_category_id ORDER BY isales.total_revenue DESC) AS rank_in_category
    FROM item_sales isales
)
SELECT
    rs.i_category_id,
    rs.i_category_name,
    rs.i_item_id,
    rs.i_name,
    rs.total_quantity,
    rs.total_revenue,
    rs.avg_price,
    rs.avg_discount_rate,
    rs.distinct_customers,
    rs.first_sale_ts,
    rs.last_sale_ts,
    rs.rank_in_category
FROM ranked_sales rs
WHERE rs.rank_in_category <= 3
ORDER BY rs.i_category_id, rs.rank_in_category
