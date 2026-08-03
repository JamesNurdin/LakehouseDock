WITH sampled_ws AS (
    SELECT *
    FROM web_sales
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    i.i_brand,
    i.i_category,
    sm.sm_type,
    SUM(sampled_ws.ws_ext_sales_price) AS total_sales,
    SUM(cr.cr_return_amount) AS total_returns,
    COUNT(DISTINCT sampled_ws.ws_order_number) AS sales_orders,
    AVG(cr.cr_net_loss) AS avg_net_loss,
    MIN(i.i_current_price) AS min_item_price
FROM sampled_ws
JOIN item i
    ON sampled_ws.ws_item_sk = i.i_item_sk
JOIN ship_mode sm
    ON sampled_ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_address ca_bill
    ON sampled_ws.ws_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship
    ON sampled_ws.ws_ship_addr_sk = ca_ship.ca_address_sk
JOIN catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
   AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN customer_address ca_return
    ON cr.cr_returning_addr_sk = ca_return.ca_address_sk
JOIN customer_address ca_refund
    ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
WHERE
    sm.sm_type = 'OVERNIGHT'
    AND sampled_ws.ws_ext_ship_cost > 1000
    AND cr.cr_reversed_charge < 100
    AND i.i_current_price > (
        SELECT MIN(i2.i_current_price)
        FROM item i2
        WHERE i2.i_category = 'Electronics'
    )
    AND EXISTS (
        SELECT 1
        FROM catalog_returns cr2
        WHERE cr2.cr_item_sk = i.i_item_sk
          AND cr2.cr_return_quantity > 0
    )
GROUP BY
    i.i_brand,
    i.i_category,
    sm.sm_type
ORDER BY total_sales DESC
LIMIT 100
