WITH cr AS (
       SELECT cr.cr_returned_date_sk,
              cr.cr_returned_time_sk,
              cr.cr_item_sk,
              cr.cr_refunded_customer_sk,
              cr.cr_refunded_hdemo_sk,
              cr.cr_return_quantity,
              cr.cr_return_amount,
              cr.cr_reason_sk,
              cr.cr_catalog_page_sk,
              cr.cr_order_number
       FROM catalog_returns cr
       WHERE cr.cr_return_amount > 50
   ),
   sr AS (
       SELECT sr.sr_returned_date_sk,
              sr.sr_item_sk,
              sr.sr_return_quantity,
              sr.sr_return_amt,
              sr.sr_reason_sk,
              sr.sr_store_sk,
              sr.sr_ticket_number,
              sr.sr_hdemo_sk
       FROM store_returns sr
       WHERE sr.sr_return_amt > 30
   )
SELECT
    cp.cp_catalog_page_id,
    cp.cp_catalog_page_number,
    ws.web_name,
    ws.web_market_manager,
    d1.d_year,
    COUNT(DISTINCT cr.cr_order_number)               AS catalog_return_orders,
    SUM(cr.cr_return_amount)                         AS total_catalog_return_amount,
    COUNT(DISTINCT sr.sr_ticket_number)              AS store_return_tickets,
    SUM(sr.sr_return_amt)                            AS total_store_return_amount,
    AVG(inv.inv_quantity_on_hand)                    AS avg_inventory_qty,
    MIN(cr.cr_return_amount)                         AS min_catalog_return,
    MAX(sr.sr_return_amt)                            AS max_store_return
FROM cr
JOIN catalog_page cp        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN date_dim d1            ON cr.cr_returned_date_sk = d1.d_date_sk
JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN reason r               ON cr.cr_reason_sk = r.r_reason_sk
JOIN store_returns sr      ON sr.sr_returned_date_sk = d1.d_date_sk
JOIN date_dim d2            ON sr.sr_returned_date_sk = d2.d_date_sk
JOIN inventory inv          ON inv.inv_date_sk = d2.d_date_sk
JOIN date_dim d3            ON cp.cp_start_date_sk = d3.d_date_sk
JOIN date_dim d4            ON cp.cp_end_date_sk   = d4.d_date_sk
JOIN web_site ws            ON ws.web_open_date_sk = d3.d_date_sk
WHERE d1.d_fy_week_seq = 6
  AND hd.hd_vehicle_count >= 2
  AND r.r_reason_desc LIKE '%Damaged%'
  AND cp.cp_catalog_page_number = 13
  AND ws.web_market_manager = 'James Harris'
  AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_hdemo_sk = hd.hd_demo_sk
          AND sr2.sr_returned_date_sk = d1.d_date_sk
          AND sr2.sr_return_amt > 100
   )
GROUP BY
    cp.cp_catalog_page_id,
    cp.cp_catalog_page_number,
    ws.web_name,
    ws.web_market_manager,
    d1.d_year
ORDER BY total_catalog_return_amount DESC
LIMIT 100
