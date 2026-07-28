WITH sales AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        'sales' AS metric_type,
        SUM(cs.cs_net_paid) AS total_amount
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_date BETWEEN DATE '2021-01-01' AND DATE '2021-12-31'
      AND sm.sm_code = 'AIR'
      AND EXISTS (
          SELECT 1
          FROM inventory inv
          WHERE inv.inv_item_sk = i.i_item_sk
            AND inv.inv_quantity_on_hand > 100
      )
    GROUP BY i.i_item_id, i.i_product_name
),
returns AS (
    SELECT
        i.i_item_id AS item_id,
        i.i_product_name AS product_name,
        'returns' AS metric_type,
        SUM(cr.cr_return_amount) AS total_amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_date BETWEEN DATE '2021-01-01' AND DATE '2021-12-31'
      AND sm.sm_code = 'AIR'
      AND EXISTS (
          SELECT 1
          FROM inventory inv
          WHERE inv.inv_item_sk = i.i_item_sk
            AND inv.inv_quantity_on_hand > 100
      )
    GROUP BY i.i_item_id, i.i_product_name
)
SELECT item_id, product_name, metric_type, total_amount
FROM sales
UNION ALL
SELECT item_id, product_name, metric_type, total_amount
FROM returns
ORDER BY total_amount DESC
LIMIT 100
