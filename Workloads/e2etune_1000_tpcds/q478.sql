WITH state_carrier_qty AS (
    SELECT
        ca.ca_state AS ca_state,
        sm.sm_carrier AS sm_carrier,
        SUM(i.inv_quantity_on_hand) AS total_quantity,
        COUNT(DISTINCT i.inv_item_sk) AS distinct_items,
        AVG(i.inv_quantity_on_hand) AS avg_quantity
    FROM customer_address ca
    JOIN inventory i
        ON i.inv_warehouse_sk = CAST(SUBSTRING(ca.ca_zip, 1, 2) AS INTEGER)
    JOIN ship_mode sm
        ON i.inv_item_sk = sm.sm_ship_mode_sk
    WHERE ca.ca_state IN ('AZ', 'NM', 'PA')
      AND i.inv_quantity_on_hand > 0
    GROUP BY ca.ca_state, sm.sm_carrier
    HAVING SUM(i.inv_quantity_on_hand) > 100
)
SELECT
    ca_state,
    sm_carrier,
    total_quantity,
    distinct_items,
    avg_quantity,
    RANK() OVER (PARTITION BY ca_state ORDER BY total_quantity DESC) AS carrier_rank
FROM state_carrier_qty
ORDER BY ca_state, carrier_rank
LIMIT 20
