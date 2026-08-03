/*
Goal: Compare store return performance between the years 2001 and 2002 for selected product categories, showing total return amount, quantity and ticket count per store while restricting to stores that have at least one high‑value return (> $1,000).
*/
WITH returns_2001 AS (
    SELECT
        s.s_store_name,
        d.d_year,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amt,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        COUNT(DISTINCT sr.sr_ticket_number) AS num_tickets
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_category_id IN (4, 8)
      AND EXISTS (
          SELECT 1
          FROM store_returns sr2
          WHERE sr2.sr_store_sk = s.s_store_sk
            AND sr2.sr_return_amt_inc_tax > 1000
      )
    GROUP BY s.s_store_name, d.d_year
),
returns_2002 AS (
    SELECT
        s.s_store_name,
        d.d_year,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amt,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        COUNT(DISTINCT sr.sr_ticket_number) AS num_tickets
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year = 2002
      AND i.i_category_id IN (4, 8)
      AND EXISTS (
          SELECT 1
          FROM store_returns sr2
          WHERE sr2.sr_store_sk = s.s_store_sk
            AND sr2.sr_return_amt_inc_tax > 1000
      )
    GROUP BY s.s_store_name, d.d_year
)
SELECT s_store_name,
       d_year,
       total_return_amt,
       total_return_qty,
       num_tickets
FROM returns_2001
UNION ALL
SELECT s_store_name,
       d_year,
       total_return_amt,
       total_return_qty,
       num_tickets
FROM returns_2002
ORDER BY d_year, total_return_amt DESC
LIMIT 100
