SELECT
    inv.inv_item_sk,
    inv.inv_warehouse_sk,
    inv.inv_quantity_on_hand,
    (inv.inv_quantity_on_hand * 1.15) AS adjusted_quantity,
    CASE
        WHEN inv.inv_quantity_on_hand = 0 THEN 'Out of Stock'
        WHEN inv.inv_quantity_on_hand < 10 THEN 'Low Stock'
        ELSE 'In Stock'
    END AS stock_status,
    d.d_date,
    d.d_year,
    d.d_month_seq,
    (d.d_month_seq % 12 + 1) AS month_of_year,
    CASE
        WHEN d.d_month_seq % 2 = 0 THEN 'Even Month'
        ELSE 'Odd Month'
    END AS month_parity,
    d.d_day_name,
    CASE
        WHEN d.d_holiday = 'Y' THEN 'Holiday'
        ELSE 'Regular Day'
    END AS day_type
FROM inventory inv
JOIN date_dim d
    ON inv.inv_date_sk = d.d_date_sk
WHERE d.d_year = 1907
  AND inv.inv_quantity_on_hand > 541
