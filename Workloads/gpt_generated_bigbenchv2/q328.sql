WITH item_sales AS (
    SELECT
        i.i_item_id,
        i.i_name,
        i.i_category_id,
        i.i_category_name,
        i.i_price,
        i.i_comp_price,
        i.i_class_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_quantity * i.i_price) AS total_revenue,
        MAX(ws.ws_ts) AS latest_ts
    FROM web_sales ws
    JOIN items i
        ON ws.ws_item_id = i.i_item_id
    GROUP BY
        i.i_item_id,
        i.i_name,
        i.i_category_id,
        i.i_category_name,
        i.i_price,
        i.i_comp_price,
        i.i_class_id
),
ranked_items AS (
    SELECT
        i_category_id,
        i_category_name,
        i_item_id,
        i_name,
        total_quantity,
        total_revenue,
        latest_ts,
        ROW_NUMBER() OVER (PARTITION BY i_category_id ORDER BY total_revenue DESC) AS rank_in_category
    FROM item_sales
)
SELECT
    i_category_id,
    i_category_name,
    i_item_id,
    i_name,
    total_quantity,
    total_revenue,
    latest_ts,
    rank_in_category
FROM ranked_items
WHERE rank_in_category <= 3
ORDER BY i_category_id, rank_in_category
