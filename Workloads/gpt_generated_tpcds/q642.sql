WITH monthly_inventory AS (
    SELECT
        date_dim.d_year,
        date_dim.d_moy,
        date_dim.d_month_seq,
        sum(inventory.inv_quantity_on_hand) AS total_quantity,
        avg(inventory.inv_quantity_on_hand) AS avg_quantity,
        count(DISTINCT inventory.inv_item_sk) AS distinct_items
    FROM inventory
    JOIN date_dim
        ON inventory.inv_date_sk = date_dim.d_date_sk
    WHERE date_dim.d_date BETWEEN DATE '1997-01-01' AND DATE '1998-12-31'
    GROUP BY date_dim.d_year, date_dim.d_moy, date_dim.d_month_seq
)
SELECT
    d_year,
    d_moy,
    total_quantity,
    avg_quantity,
    distinct_items,
    total_quantity - LAG(total_quantity) OVER (PARTITION BY d_year ORDER BY d_month_seq) AS qty_change_from_prev_month,
    total_quantity / NULLIF(distinct_items, 0) AS avg_quantity_per_item,
    RANK() OVER (PARTITION BY d_year ORDER BY total_quantity DESC) AS month_rank_by_quantity
FROM monthly_inventory
WHERE d_year = 1998
ORDER BY d_month_seq
