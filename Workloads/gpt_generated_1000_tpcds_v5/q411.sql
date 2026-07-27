/*
Goal: Compare yearly total store return amounts for high‑spending female customers against yearly total inventory on hand for selected warehouses, combining the two metrics with a UNION ALL.
*/
WITH returns AS (
    SELECT
        d.d_year AS year,
        'return' AS metric,
        SUM(sr.sr_return_amt) AS total_amount
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F'
      AND cd.cd_purchase_estimate > 5000
      AND EXISTS (
            SELECT 1
            FROM customer_demographics cd2
            WHERE cd2.cd_demo_sk = cd.cd_demo_sk
              AND cd2.cd_dep_employed_count > 2
          )
    GROUP BY d.d_year
),
inventory_totals AS (
    SELECT
        d.d_year AS year,
        'inventory' AS metric,
        SUM(i.inv_quantity_on_hand) AS total_amount
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    WHERE i.inv_warehouse_sk IN (10, 20)
      AND d.d_year BETWEEN 2000 AND 2005
    GROUP BY d.d_year
)
SELECT
    r.year,
    r.metric,
    r.total_amount
FROM returns r
UNION ALL
SELECT
    i.year,
    i.metric,
    i.total_amount
FROM inventory_totals i
ORDER BY year DESC, metric
LIMIT 100
