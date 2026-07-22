WITH returns AS (
    SELECT
        d.d_date AS event_date,
        s.s_store_name AS entity_name,
        'ReturnAmount' AS metric_type,
        SUM(sr.sr_return_amt) AS metric_value,
        CASE
            WHEN SUM(sr.sr_return_amt) > (SELECT AVG(sr2.sr_return_amt) FROM store_returns sr2)
                THEN 'High'
            ELSE 'Low'
        END AS metric_category
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE d.d_day_name = 'Friday'
      AND s.s_state = 'CA'
      AND sr.sr_cdemo_sk IN (
          SELECT cd.cd_demo_sk
          FROM customer_demographics cd
          WHERE cd.cd_gender = 'F'
      )
    GROUP BY d.d_date, s.s_store_name
),
inventory_agg AS (
    SELECT
        d.d_date AS event_date,
        w.w_warehouse_name AS entity_name,
        'InventoryQty' AS metric_type,
        CAST(SUM(i.inv_quantity_on_hand) AS decimal(15,2)) AS metric_value,
        CASE
            WHEN SUM(i.inv_quantity_on_hand) > (SELECT AVG(inv_quantity_on_hand) FROM inventory)
                THEN 'High'
            ELSE 'Low'
        END AS metric_category
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_day_name = 'Friday'
      AND w.w_state = 'CA'
    GROUP BY d.d_date, w.w_warehouse_name
)
SELECT event_date, entity_name, metric_type, metric_value, metric_category
FROM returns
UNION ALL
SELECT event_date, entity_name, metric_type, metric_value, metric_category
FROM inventory_agg
ORDER BY event_date DESC, metric_type, entity_name
LIMIT 100
