WITH
    filtered_sales AS (
        SELECT
            ss.ss_ticket_number,
            ss.ss_net_paid,
            ss.ss_sold_date_sk,
            ss.ss_addr_sk,
            ss.ss_store_sk
        FROM store_sales ss
        WHERE ss.ss_net_paid > 1000
          AND ss.ss_quantity >= 2
    ),
    agg AS (
        SELECT
            cc.cc_name,
            w.w_warehouse_name,
            ca.ca_state,
            w.w_state,
            COUNT(DISTINCT fs.ss_ticket_number)               AS num_sales,
            SUM(fs.ss_net_paid)                               AS total_net_paid,
            AVG(cr.cr_return_amount)                          AS avg_return_amount,
            SUM(cr.cr_return_amount)                          AS total_return_amount,
            MIN(inv.inv_quantity_on_hand)                     AS min_qty_on_hand,
            MAX(inv.inv_quantity_on_hand)                     AS max_qty_on_hand
        FROM filtered_sales fs
        JOIN customer_address ca ON fs.ss_addr_sk = ca.ca_address_sk
        JOIN catalog_returns cr ON cr.cr_refunded_addr_sk = ca.ca_address_sk
        JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
        WHERE cc.cc_state = 'CA'
          AND w.w_county = 'Daviess County'
          AND w.w_warehouse_sq_ft > 200000
          AND inv.inv_quantity_on_hand < 500
          AND cr.cr_return_amount BETWEEN 50 AND 500
          AND ca.ca_state = 'TX'
          AND EXISTS (
                SELECT 1
                FROM catalog_returns cr2
                WHERE cr2.cr_warehouse_sk = w.w_warehouse_sk
                  AND cr2.cr_return_amount > 400
          )
        GROUP BY
            cc.cc_name,
            w.w_warehouse_name,
            ca.ca_state,
            w.w_state
    )
SELECT
    cc_name,
    w_warehouse_name,
    ca_state,
    w_state,
    num_sales,
    total_net_paid,
    avg_return_amount,
    total_return_amount,
    min_qty_on_hand,
    max_qty_on_hand,
    SUM(total_net_paid) OVER (PARTITION BY w_state ORDER BY total_net_paid DESC ROWS UNBOUNDED PRECEDING) AS cum_net_paid_by_state
FROM agg
ORDER BY total_net_paid DESC
LIMIT 50
