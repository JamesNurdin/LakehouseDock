WITH inv_agg AS (
    SELECT inv_item_sk,
           inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS total_qty_on_hand
    FROM inventory
    WHERE inv_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2002
          AND d_month_seq BETWEEN 1 AND 12
    )
    GROUP BY inv_item_sk, inv_warehouse_sk
)
SELECT
    d.d_year,
    cc.cc_name,
    i.i_category,
    sm.sm_carrier,
    w.w_warehouse_name,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    SUM(cr.cr_net_loss) AS total_catalog_net_loss,
    SUM(wr.wr_net_loss) AS total_web_net_loss,
    SUM(inv_agg.total_qty_on_hand) AS total_inventory_qty,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_orders,
    COUNT(DISTINCT wr.wr_order_number) AS web_orders
FROM catalog_returns cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN item i ON cr.cr_item_sk = i.i_item_sk
JOIN customer_address ca_refund ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
JOIN customer_address ca_return ON cr.cr_returning_addr_sk = ca_return.ca_address_sk
JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
                     AND wr.wr_returned_date_sk = d.d_date_sk
JOIN customer_address ca_w_refund ON wr.wr_refunded_addr_sk = ca_w_refund.ca_address_sk
JOIN customer_address ca_w_return ON wr.wr_returning_addr_sk = ca_w_return.ca_address_sk
JOIN inv_agg ON inv_agg.inv_item_sk = i.i_item_sk
               AND inv_agg.inv_warehouse_sk = w.w_warehouse_sk
WHERE d.d_year = 2002
  AND sm.sm_carrier = 'FEDEX'
  AND cc.cc_state = 'CA'
  AND w.w_state = 'TX'
GROUP BY d.d_year, cc.cc_name, i.i_category, sm.sm_carrier, w.w_warehouse_name
ORDER BY total_catalog_return_amount DESC
LIMIT 100
