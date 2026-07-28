WITH item_price_avg AS (
    SELECT avg(i_current_price) AS avg_price
    FROM item
)
SELECT
    d.d_year AS year,
    i.i_category AS category,
    'sales' AS metric_type,
    SUM(ss.ss_ext_sales_price) AS metric_value,
    CASE WHEN SUM(ss.ss_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS flag,
    (SELECT avg_price FROM item_price_avg) AS overall_avg_price
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN item i ON ss.ss_item_sk = i.i_item_sk
WHERE d.d_year = 2001
  AND i.i_category = 'Sports'
GROUP BY d.d_year, i.i_category

UNION ALL

SELECT
    d.d_year AS year,
    i.i_category AS category,
    'inventory' AS metric_type,
    SUM(inv.inv_quantity_on_hand * i.i_current_price) AS metric_value,
    CASE WHEN SUM(inv.inv_quantity_on_hand) > 1000 THEN 'HIGH' ELSE 'LOW' END AS flag,
    (SELECT avg_price FROM item_price_avg) AS overall_avg_price
FROM inventory inv
JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
JOIN item i ON inv.inv_item_sk = i.i_item_sk
WHERE d.d_year = 2001
  AND i.i_category = 'Sports'
  AND EXISTS (
        SELECT 1
        FROM store_sales ss2
        WHERE ss2.ss_item_sk = i.i_item_sk
          AND ss2.ss_sold_date_sk = d.d_date_sk
          AND ss2.ss_ext_sales_price > 0
      )
GROUP BY d.d_year, i.i_category
ORDER BY year DESC, metric_type, metric_value DESC
LIMIT 100
