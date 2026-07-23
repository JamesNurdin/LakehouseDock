WITH date_range AS (
    SELECT
        d_date_sk,
        d_year,
        d_moy
    FROM date_dim
    WHERE d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
)
SELECT
    dr.d_year AS year,
    dr.d_moy AS month,
    i.i_category AS category,
    'sales' AS metric,
    SUM(ss.ss_net_paid) AS amount
FROM store_sales ss
JOIN date_range dr
    ON ss.ss_sold_date_sk = dr.d_date_sk
JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
GROUP BY dr.d_year, dr.d_moy, i.i_category

UNION ALL

SELECT
    dr.d_year AS year,
    dr.d_moy AS month,
    i.i_category AS category,
    'inventory' AS metric,
    SUM(inv.inv_quantity_on_hand) AS amount
FROM inventory inv
JOIN date_range dr
    ON inv.inv_date_sk = dr.d_date_sk
JOIN item i
    ON inv.inv_item_sk = i.i_item_sk
GROUP BY dr.d_year, dr.d_moy, i.i_category
ORDER BY year, month, category, metric
LIMIT 100
