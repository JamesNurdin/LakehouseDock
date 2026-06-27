WITH monthly_category_inventory AS (
    SELECT
        date_dim.d_year,
        date_dim.d_month_seq,
        item.i_category,
        sum(inventory.inv_quantity_on_hand) AS total_quantity,
        sum(inventory.inv_quantity_on_hand * item.i_current_price) AS total_inventory_value,
        avg(item.i_current_price) AS avg_price,
        count(distinct item.i_item_sk) AS distinct_items
    FROM inventory
    JOIN date_dim ON inventory.inv_date_sk = date_dim.d_date_sk
    JOIN item ON inventory.inv_item_sk = item.i_item_sk
    WHERE date_dim.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
    GROUP BY date_dim.d_year, date_dim.d_month_seq, item.i_category
)
SELECT
    d_year,
    d_month_seq,
    i_category,
    total_quantity,
    total_inventory_value,
    avg_price,
    distinct_items,
    rank() OVER (PARTITION BY d_year, d_month_seq ORDER BY total_inventory_value DESC) AS category_rank
FROM monthly_category_inventory
ORDER BY d_year, d_month_seq, category_rank
