WITH avg_price_by_class AS (
    SELECT i_class,
           AVG(i_current_price) AS avg_price
    FROM item
    GROUP BY i_class
)
SELECT
    'Sales' AS source_type,
    d.d_year,
    d.d_month_seq,
    CASE WHEN i.i_color = 'red' THEN 'Red' ELSE 'Other' END AS color_group,
    SUM(ss.ss_ext_sales_price) AS amount,
    (SELECT ap.avg_price FROM avg_price_by_class ap WHERE ap.i_class = i.i_class) AS class_avg_price
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
WHERE d.d_moy = 7
  AND d.d_year = 2022
GROUP BY d.d_year, d.d_month_seq, i.i_color, i.i_class

UNION ALL

SELECT
    'Inventory' AS source_type,
    d.d_year,
    d.d_month_seq,
    CASE WHEN i.i_color = 'red' THEN 'Red' ELSE 'Other' END AS color_group,
    SUM(inv.inv_quantity_on_hand) AS amount,
    (SELECT ap.avg_price FROM avg_price_by_class ap WHERE ap.i_class = i.i_class) AS class_avg_price
FROM inventory inv
JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
JOIN item i ON inv.inv_item_sk = i.i_item_sk
WHERE d.d_fy_quarter_seq = 5
  AND d.d_year = 2022
GROUP BY d.d_year, d.d_month_seq, i.i_color, i.i_class

ORDER BY source_type, d_year, d_month_seq, color_group
