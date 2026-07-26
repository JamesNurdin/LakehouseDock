WITH site_periods AS (
    SELECT
        ws.web_site_sk,
        od.d_date AS open_date,
        cd.d_date AS close_date
    FROM web_site ws
    JOIN date_dim od ON ws.web_open_date_sk = od.d_date_sk
    JOIN date_dim cd ON ws.web_close_date_sk = cd.d_date_sk
),
 daily_inventory AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        d.d_date,
        d.d_year,
        inv.inv_quantity_on_hand,
        LAG(inv.inv_quantity_on_hand) OVER (PARTITION BY i.i_item_sk ORDER BY d.d_date) AS prev_qty,
        sp.web_site_sk
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN site_periods sp
        ON d.d_date BETWEEN sp.open_date AND sp.close_date
    WHERE d.d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
)
SELECT
    i_item_sk,
    i_category,
    d_date,
    inv_quantity_on_hand,
    prev_qty,
    inv_quantity_on_hand - prev_qty AS qty_change,
    CASE
        WHEN inv_quantity_on_hand - prev_qty > 0 THEN 'Increase'
        WHEN inv_quantity_on_hand - prev_qty < 0 THEN 'Decrease'
        ELSE 'No Change'
    END AS change_type,
    RANK() OVER (PARTITION BY i_category ORDER BY ABS(inv_quantity_on_hand - prev_qty) DESC) AS change_rank,
    web_site_sk
FROM daily_inventory
WHERE prev_qty IS NOT NULL
ORDER BY i_category, change_rank
