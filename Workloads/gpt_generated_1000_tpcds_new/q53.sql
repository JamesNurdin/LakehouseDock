WITH cr AS (
    SELECT
        cr_returned_date_sk,
        cr_item_sk,
        cr_refunded_customer_sk,
        cr_refunded_addr_sk,
        cr_returning_customer_sk,
        cr_returning_addr_sk,
        cr_ship_mode_sk,
        cr_warehouse_sk,
        cr_reason_sk,
        cr_order_number,
        cr_return_quantity,
        cr_return_amount,
        cr_fee,
        cr_return_tax,
        cr_reversed_charge,
        cr_net_loss
    FROM catalog_returns cr
    WHERE cr_returned_date_sk IN (
        SELECT d_date_sk FROM date_dim WHERE d_year = 2000
    )
      AND cr_return_amount > 100
      AND cr_fee < 50
),
anti AS (
    SELECT ss_ticket_number FROM store_sales WHERE ss_sold_date_sk = 99999
)
SELECT
    d.d_year,
    i.i_category,
    w.w_warehouse_name,
    sm.sm_type,
    r.r_reason_desc,
    COUNT(DISTINCT cr.cr_order_number) AS return_orders,
    SUM(cr.cr_return_quantity) AS total_return_qty,
    SUM(cr.cr_return_amount) AS total_return_amount,
    AVG(cr.cr_fee) AS avg_fee,
    MIN(cr.cr_net_loss) AS min_net_loss,
    MAX(cr.cr_net_loss) AS max_net_loss
FROM cr
JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
JOIN item i ON cr.cr_item_sk = i.i_item_sk
JOIN customer c_refund ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
JOIN customer_address ca_refund ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    AND ss.ss_item_sk = i.i_item_sk
    AND ss.ss_customer_sk = c_refund.c_customer_sk
WHERE ss.ss_net_paid > 0
  AND cr.cr_order_number NOT IN (SELECT ss_ticket_number FROM anti)
GROUP BY d.d_year, i.i_category, w.w_warehouse_name, sm.sm_type, r.r_reason_desc
HAVING SUM(cr.cr_return_amount) > 500
ORDER BY total_return_amount DESC
LIMIT 100
