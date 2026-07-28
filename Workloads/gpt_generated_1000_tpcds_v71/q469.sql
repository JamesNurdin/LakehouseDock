WITH inv_summary AS (
    SELECT
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand,
        COUNT(DISTINCT inv_warehouse_sk) AS warehouse_count
    FROM inventory
    WHERE inv_quantity_on_hand > 10
      AND inv_warehouse_sk IN (3, 5, 6, 8, 12)
    GROUP BY inv_item_sk
),
returns_summary AS (
    SELECT
        wr_order_number,
        SUM(wr_return_amt) AS total_return_amt,
        COUNT(*) AS return_cnt
    FROM web_returns
    WHERE wr_return_amt > 100
      AND wr_reason_sk IN (21, 27, 31, 34, 37)
    GROUP BY wr_order_number
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    ca_bill.ca_state AS bill_state,
    ca_ship.ca_state AS ship_state,
    sm.sm_carrier,
    ws.ws_net_paid_inc_tax,
    ss.ss_net_paid,
    inv_sum.total_qty_on_hand,
    inv_sum.warehouse_count,
    ret_sum.total_return_amt,
    ret_sum.return_cnt
FROM inv_summary inv_sum
JOIN item i ON i.i_item_sk = inv_sum.inv_item_sk
JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
JOIN customer_address ca_store ON ca_store.ca_address_sk = ss.ss_addr_sk
JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
JOIN customer_address ca_bill ON ca_bill.ca_address_sk = ws.ws_bill_addr_sk
JOIN customer_address ca_ship ON ca_ship.ca_address_sk = ws.ws_ship_addr_sk
JOIN ship_mode sm ON sm.sm_ship_mode_sk = ws.ws_ship_mode_sk
JOIN web_page wp ON wp.wp_web_page_sk = ws.ws_web_page_sk
LEFT JOIN returns_summary ret_sum ON ret_sum.wr_order_number = ws.ws_order_number
WHERE i.i_current_price BETWEEN 10 AND 500
  AND i.i_brand_id IN (1, 2, 3, 4, 5)
  AND ss.ss_quantity > 1
  AND ws.ws_ship_date_sk BETWEEN 2450829 AND 2451081
  AND ca_store.ca_country = 'United States'
ORDER BY inv_sum.total_qty_on_hand DESC, ws.ws_net_paid_inc_tax DESC
LIMIT 100
