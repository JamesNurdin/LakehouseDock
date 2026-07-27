WITH inventory_agg AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 500
      AND inv_warehouse_sk IN (6, 11, 15)
    GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT
    i.i_brand,
    ca_refunded.ca_county,
    COUNT(DISTINCT cr.cr_order_number) AS num_returns,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_return_ship_cost) AS avg_ship_cost,
    MIN(cr.cr_return_amount) AS min_return_amount,
    MAX(cr.cr_return_amount) AS max_return_amount,
    SUM(ia.total_qty_on_hand) AS total_inventory_qty
FROM catalog_returns cr
JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
JOIN inventory_agg ia
    ON i.i_item_sk = ia.inv_item_sk
JOIN customer_address ca_refunded
    ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN customer_address ca_returning
    ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
WHERE cr.cr_return_ship_cost > 100
  AND cr.cr_return_quantity = 1
  AND cr.cr_warehouse_sk = 1
  AND cr.cr_returned_time_sk BETWEEN 20000 AND 60000
  AND i.i_brand = 'Brand#23'
  AND ca_refunded.ca_location_type = 'apartment'
  AND ca_refunded.ca_county = 'Maricopa County'
GROUP BY i.i_brand, ca_refunded.ca_county
ORDER BY total_return_amount DESC
LIMIT 100
