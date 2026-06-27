WITH daily_agg AS (
    SELECT
        d.d_date,
        i.i_category,
        i.i_brand,
        SUM(inv.inv_quantity_on_hand) AS total_quantity,
        AVG(i.i_current_price) AS avg_price
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY d.d_date, i.i_category, i.i_brand
)
SELECT
    d_date,
    i_category,
    i_brand,
    total_quantity,
    avg_price,
    total_quantity * avg_price AS total_inventory_value,
    SUM(total_quantity * avg_price) OVER (
        PARTITION BY i_category
        ORDER BY d_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS rolling_7day_value
FROM daily_agg
ORDER BY d_date, i_category, i_brand
