WITH inventory_metrics AS (
    SELECT
        'Inventory' AS metric_type,
        w.w_warehouse_id AS location_key,
        CAST(SUM(i.inv_quantity_on_hand) AS DOUBLE) AS amount,
        CASE
            WHEN w.w_gmt_offset < -6.0 THEN 'Pacific'
            WHEN w.w_gmt_offset < -5.0 THEN 'Mountain'
            ELSE 'Central'
        END AS region
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_date BETWEEN DATE '2021-01-01' AND DATE '2021-12-31'
    GROUP BY w.w_warehouse_id, w.w_gmt_offset
),
return_metrics AS (
    SELECT
        'Return' AS metric_type,
        ca.ca_state AS location_key,
        CAST(SUM(sr.sr_return_amt) AS DOUBLE) AS amount,
        CASE
            WHEN ca.ca_state IN ('CA', 'OR', 'WA') THEN 'West'
            ELSE 'East'
        END AS region
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE d.d_date BETWEEN DATE '2021-01-01' AND DATE '2021-12-31'
      AND EXISTS (
          SELECT 1
          FROM customer c
          WHERE c.c_customer_sk = sr.sr_customer_sk
            AND c.c_preferred_cust_flag = 'Y'
      )
    GROUP BY ca.ca_state
)
SELECT metric_type, location_key, amount, region
FROM (
    SELECT metric_type, location_key, amount, region FROM inventory_metrics
    UNION ALL
    SELECT metric_type, location_key, amount, region FROM return_metrics
) AS combined
ORDER BY metric_type, amount DESC
OFFSET 0
LIMIT 100
