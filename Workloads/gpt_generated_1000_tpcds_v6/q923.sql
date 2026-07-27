WITH high_cost_manufacturers AS (
    SELECT DISTINCT i_manufact_id
    FROM item
    WHERE i_wholesale_cost > 20
)
SELECT *
FROM (
    SELECT
        i.i_manufact_id AS manufact_id,
        'Return' AS metric_type,
        SUM(wr.wr_return_amt) AS metric_value,
        CASE WHEN SUM(wr.wr_return_amt) > 5000 THEN 'High' ELSE 'Normal' END AS metric_category
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_manufact_id IN (SELECT i_manufact_id FROM high_cost_manufacturers)
    GROUP BY i.i_manufact_id
    HAVING SUM(wr.wr_return_amt) > 1000

    UNION ALL

    SELECT
        i.i_manufact_id AS manufact_id,
        'Inventory' AS metric_type,
        SUM(inv.inv_quantity_on_hand) AS metric_value,
        CASE WHEN SUM(inv.inv_quantity_on_hand) > 2000 THEN 'High' ELSE 'Normal' END AS metric_category
    FROM inventory inv
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Electronics'
    GROUP BY i.i_manufact_id
    HAVING SUM(inv.inv_quantity_on_hand) > 500
) combined
ORDER BY metric_value DESC
LIMIT 100
