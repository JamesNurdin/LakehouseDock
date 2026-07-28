/*
  Goal: Identify the top‑selling items in 2001 for customers born in May, excluding any items that were ever returned (store or catalog returns). The query combines sales from brick‑and‑mortar stores and the web channel using UNION ALL, applies anti‑joins (NOT EXISTS), uses DISTINCT, a scalar sub‑query for a comparative threshold, aggregates the results, orders by total net paid and limits to 100 rows.
*/
SELECT
  combined.item_id,
  combined.product_name,
  combined.year,
  SUM(combined.net_paid) AS total_net_paid
FROM (
    SELECT DISTINCT
      i.i_item_id        AS item_id,
      i.i_product_name   AS product_name,
      d.d_year           AS year,
      ss.ss_net_paid     AS net_paid
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND c.c_birth_month = 5
      AND NOT EXISTS (
            SELECT 1
            FROM store_returns sr
            WHERE sr.sr_item_sk = i.i_item_sk
              AND sr.sr_ticket_number = ss.ss_ticket_number
      )
    UNION ALL
    SELECT DISTINCT
      i.i_item_id,
      i.i_product_name,
      d.d_year,
      ws.ws_net_paid
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND c.c_birth_month = 5
      AND NOT EXISTS (
            SELECT 1
            FROM catalog_returns cr
            WHERE cr.cr_item_sk = i.i_item_sk
              AND cr.cr_order_number = ws.ws_order_number
      )
) AS combined
GROUP BY combined.item_id, combined.product_name, combined.year
HAVING SUM(combined.net_paid) > (
    SELECT AVG(ss2.ss_net_paid)
    FROM store_sales ss2
    JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2001
)
ORDER BY total_net_paid DESC
LIMIT 100
