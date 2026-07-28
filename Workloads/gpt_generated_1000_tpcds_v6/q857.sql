WITH inventory_by_date AS (
    SELECT inv_date_sk,
           inv_warehouse_sk,
           inv_quantity_on_hand
    FROM inventory
    WHERE inv_warehouse_sk IN (5, 12)
)

SELECT
    d.d_date AS return_date,
    ca.ca_state AS refunded_state,
    wr.wr_return_quantity AS return_quantity,
    wr.wr_net_loss AS net_loss,
    ibd.inv_quantity_on_hand AS inventory_on_hand
FROM web_returns wr
JOIN date_dim d
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN customer_address ca
    ON wr.wr_refunded_addr_sk = ca.ca_address_sk
JOIN inventory_by_date ibd
    ON wr.wr_returned_date_sk = ibd.inv_date_sk
WHERE d.d_year = 2001
  AND wr.wr_net_loss > 200
  AND ibd.inv_quantity_on_hand < 100

UNION ALL

SELECT
    d.d_date AS return_date,
    ca.ca_state AS refunded_state,
    wr.wr_return_quantity AS return_quantity,
    wr.wr_net_loss AS net_loss,
    ibd.inv_quantity_on_hand AS inventory_on_hand
FROM web_returns wr
JOIN date_dim d
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN customer_address ca
    ON wr.wr_refunded_addr_sk = ca.ca_address_sk
JOIN inventory_by_date ibd
    ON wr.wr_returned_date_sk = ibd.inv_date_sk
WHERE d.d_year = 2001
  AND wr.wr_net_loss <= 200
  AND ibd.inv_quantity_on_hand >= 100

ORDER BY return_date DESC, net_loss DESC
LIMIT 100
