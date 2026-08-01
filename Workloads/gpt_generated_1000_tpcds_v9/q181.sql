/*
Goal: Analyze sales and return performance across products, customers, and warehouses for a specific period, focusing on high‑value items purchased by customers with an advanced education degree. Compute total sales, distinct transaction count, average return amount, total refunded cash, and maximum inventory on hand.
*/
WITH base_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_quantity,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_ticket_number,
        ss.ss_ext_sales_price
    FROM store_sales ss
    WHERE ss.ss_sold_date_sk BETWEEN 2450000 AND 2450500
      AND ss.ss_quantity > 0
)
SELECT
    i.i_item_id,
    i.i_product_name,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cd.cd_education_status,
    hd.hd_buy_potential,
    w.w_warehouse_name,
    SUM(ss.ss_ext_sales_price)           AS total_sales,
    COUNT(DISTINCT ss.ss_ticket_number)  AS distinct_transactions,
    AVG(sr.sr_return_amt)                AS avg_return_amount,
    SUM(wr.wr_refunded_cash)             AS total_refunded_cash,
    MAX(inv.inv_quantity_on_hand)        AS max_qty_on_hand
FROM base_sales ss
JOIN item i ON ss.ss_item_sk = i.i_item_sk
JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    AND sr.sr_item_sk = i.i_item_sk
LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    AND wr.wr_returning_customer_sk = c.c_customer_sk
WHERE i.i_current_price BETWEEN 10.00 AND 500.00
  AND cd.cd_education_status = 'Advanced Degree'
  AND hd.hd_buy_potential = 'Medium'
  AND w.w_state = 'CA'
  AND inv.inv_quantity_on_hand > 0
  AND EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_ticket_number = ss.ss_ticket_number
          AND sr2.sr_return_amt > 100.00
    )
GROUP BY
    i.i_item_id,
    i.i_product_name,
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cd.cd_education_status,
    hd.hd_buy_potential,
    w.w_warehouse_name
ORDER BY total_sales DESC
LIMIT 100
