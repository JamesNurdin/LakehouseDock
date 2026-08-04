WITH intersect_orders AS (
    SELECT wr_order_number FROM web_returns WHERE wr_return_quantity > 5
    INTERSECT
    SELECT wr_order_number FROM web_returns WHERE wr_net_loss > 100
)
SELECT
    wr.wr_order_number,
    i.i_item_id,
    i.i_product_name,
    ca.ca_state,
    ca.ca_city,
    hd.hd_vehicle_count,
    wr.wr_net_loss,
    ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY wr.wr_net_loss DESC) AS loss_rank
FROM web_returns AS wr
JOIN item AS i
    ON wr.wr_item_sk = i.i_item_sk
JOIN household_demographics AS hd
    ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN customer_address AS ca
    ON wr.wr_refunded_addr_sk = ca.ca_address_sk
JOIN intersect_orders io
    ON wr.wr_order_number = io.wr_order_number
WHERE ca.ca_state = 'CA'
  AND ca.ca_location_type = 'condo'
  AND hd.hd_vehicle_count >= 1
  AND i.i_current_price BETWEEN 10 AND 500
  AND wr.wr_net_loss > 0
  AND NOT EXISTS (
        SELECT 1 FROM web_returns AS wr2
        WHERE wr2.wr_item_sk = wr.wr_item_sk
          AND wr2.wr_returned_date_sk > wr.wr_returned_date_sk
    )
ORDER BY loss_rank, ca.ca_state
OFFSET 0 LIMIT 100
