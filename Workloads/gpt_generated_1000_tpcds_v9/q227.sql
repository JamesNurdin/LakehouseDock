/*
  Goal: Summarize per‑item performance for the year 2000 by combining sales and returns, 
  compute total sales and return amounts, distinct counts of customers and transactions, 
  fetch the total inventory on hand for each item as of 2001 via a lateral join, rank items by sales, 
  and return the top 100 items.
*/
WITH sales_and_returns AS (
    SELECT DISTINCT
        ss.ss_item_sk AS i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        ss.ss_ext_sales_price AS amount,
        ss.ss_customer_sk AS customer_sk,
        ss.ss_ticket_number AS ticket_number,
        'sale' AS txn_type
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2000

    UNION ALL

    SELECT DISTINCT
        sr.sr_item_sk AS i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        sr.sr_return_amt AS amount,
        sr.sr_customer_sk AS customer_sk,
        sr.sr_ticket_number AS ticket_number,
        'return' AS txn_type
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
),
aggregated AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        SUM(CASE WHEN s.txn_type = 'sale'   THEN s.amount ELSE 0 END) AS total_sales_amount,
        SUM(CASE WHEN s.txn_type = 'return' THEN s.amount ELSE 0 END) AS total_return_amount,
        COUNT(DISTINCT s.customer_sk)   AS distinct_customers,
        COUNT(DISTINCT s.ticket_number) AS distinct_transactions,
        ROW_NUMBER() OVER (ORDER BY SUM(CASE WHEN s.txn_type = 'sale' THEN s.amount ELSE 0 END) DESC) AS row_num
    FROM sales_and_returns s
    JOIN item i ON s.i_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk, i.i_item_id, i.i_item_desc
)
SELECT
    a.i_item_id,
    a.i_item_desc,
    a.total_sales_amount,
    a.total_return_amount,
    a.distinct_customers,
    a.distinct_transactions,
    inv.total_inventory,
    a.row_num
FROM aggregated a
CROSS JOIN LATERAL (
    SELECT SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM inventory inv
    JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
    WHERE inv.inv_item_sk = a.i_item_sk
      AND d.d_year = 2001
) AS inv
ORDER BY a.total_sales_amount DESC
LIMIT 100
