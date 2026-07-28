/*
Goal: Analyze combined store, catalog and web sales performance for the year 2001, broken down by year/month, warehouse and store‑return reason. The query joins all 15 selected TPC‑DS tables, re‑uses the CUSTOMER and REASON tables under different aliases, includes a scalar CTE, an EXISTS sub‑query, a CASE expression, aggregates, ordering and a LIMIT.
*/
WITH filtered_inventory AS (
    SELECT inv_warehouse_sk,
           inv_date_sk,
           inv_quantity_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 0
)
SELECT
    d.d_year,
    d.d_month_seq,
    w.w_warehouse_name,
    r_store.r_reason_desc AS store_return_reason,
    CASE WHEN SUM(ss.ss_net_paid) - SUM(cr.cr_return_amount) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_status,
    SUM(ss.ss_net_paid)              AS total_store_sales,
    SUM(cr.cr_return_amount)          AS total_catalog_returns,
    SUM(ws.ws_net_paid)               AS total_web_sales,
    SUM(wr.wr_return_amt)             AS total_web_returns,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer c_store ON ss.ss_customer_sk = c_store.c_customer_sk
JOIN household_demographics hd_store ON ss.ss_hdemo_sk = hd_store.hd_demo_sk
JOIN customer_address ca_store ON ss.ss_addr_sk = ca_store.ca_address_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN reason r_store ON sr.sr_reason_sk = r_store.r_reason_sk
JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
JOIN customer c_refunded ON cr.cr_refunded_customer_sk = c_refunded.c_customer_sk
JOIN customer c_returning ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN filtered_inventory inv ON inv.inv_date_sk = d.d_date_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
JOIN reason r_web ON wr.wr_reason_sk = r_web.r_reason_sk
WHERE d.d_year = 2001
  AND EXISTS (
        SELECT 1
        FROM inventory inv_check
        WHERE inv_check.inv_warehouse_sk = w.w_warehouse_sk
          AND inv_check.inv_quantity_on_hand > 5000
      )
GROUP BY d.d_year,
         d.d_month_seq,
         w.w_warehouse_name,
         r_store.r_reason_desc
ORDER BY total_store_sales DESC
LIMIT 100
