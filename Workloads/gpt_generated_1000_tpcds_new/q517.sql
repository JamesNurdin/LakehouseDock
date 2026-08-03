WITH
    inventory_sampled AS (
        SELECT inv_date_sk, inv_item_sk, inv_warehouse_sk, inv_quantity_on_hand
        FROM inventory
        TABLESAMPLE BERNOULLI (10)
        WHERE inv_quantity_on_hand IS NOT NULL
    ),
    date_filtered AS (
        SELECT d_date_sk, d_date, d_year, d_month_seq, d_quarter_name, d_holiday
        FROM date_dim
        WHERE d_year = 2000
          AND d_month_seq BETWEEN 1200 AND 1300
    ),
    diff_items AS (
        SELECT inv_item_sk FROM inventory WHERE inv_quantity_on_hand > 0
        EXCEPT
        SELECT inv_item_sk FROM inventory WHERE inv_warehouse_sk = 13
    )
SELECT
    d.d_date,
    inv.inv_warehouse_sk,
    inv.inv_item_sk,
    inv.inv_quantity_on_hand,
    wp.wp_url,
    wp.wp_type,
    CASE WHEN inv.inv_quantity_on_hand > 100 THEN 'High' ELSE 'Low' END AS qty_category,
    ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY inv.inv_quantity_on_hand DESC) AS rn_quantity_year,
    RANK() OVER (PARTITION BY wp.wp_type ORDER BY d.d_month_seq) AS rk_month_type,
    max_q.max_qty_for_date,
    lat.items_in_warehouse
FROM date_filtered d
JOIN inventory_sampled inv ON inv.inv_date_sk = d.d_date_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
LEFT JOIN LATERAL (
    SELECT COUNT(DISTINCT i2.inv_item_sk) AS items_in_warehouse
    FROM inventory i2
    WHERE i2.inv_warehouse_sk = inv.inv_warehouse_sk
      AND i2.inv_date_sk = inv.inv_date_sk
) lat ON TRUE
LEFT JOIN LATERAL (
    SELECT MAX(i3.inv_quantity_on_hand) AS max_qty_for_date
    FROM inventory i3
    WHERE i3.inv_date_sk = inv.inv_date_sk
) max_q ON TRUE
WHERE
    d.d_quarter_name = 'Q1'
    AND d.d_holiday = 'N'
    AND inv.inv_quantity_on_hand BETWEEN 10 AND 500
    AND inv.inv_warehouse_sk IN (2, 14, 19)
    AND wp.wp_type = 'product'
    AND wp.wp_rec_end_date > DATE '2000-01-01'
    AND EXISTS (SELECT 1 FROM diff_items di WHERE di.inv_item_sk = inv.inv_item_sk)
ORDER BY d.d_date DESC, rn_quantity_year
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
