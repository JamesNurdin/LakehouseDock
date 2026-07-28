/*
Goal: Identify the top customers (by total return amount across catalog, store, and web returns) for the year 2000, limited to male customers in Texas, and rank them. The query joins all nine selected TPC‑DS tables, applies several filters, uses an EXISTS semi‑join for the web_page table, and ranks the results with a window function.
*/
WITH base AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cr.cr_return_amount,
        sr.sr_return_amt,
        wr.wr_return_amt,
        d1.d_year AS sale_year,
        d2.d_year AS store_return_year,
        d3.d_year AS catalog_return_year,
        d4.d_year AS web_return_year,
        ca.ca_state,
        cd.cd_gender,
        sr.sr_fee,
        cr.cr_return_tax
    FROM store_sales ss
    JOIN date_dim d1
      ON ss.ss_sold_date_sk = d1.d_date_sk
    JOIN customer c
      ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
      ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
      ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr
      ON sr.sr_item_sk = ss.ss_item_sk
     AND sr.sr_ticket_number = ss.ss_ticket_number
     AND sr.sr_customer_sk = c.c_customer_sk
     AND sr.sr_cdemo_sk = cd.cd_demo_sk
     AND sr.sr_addr_sk = ca.ca_address_sk
    LEFT JOIN date_dim d2
      ON sr.sr_returned_date_sk = d2.d_date_sk
    LEFT JOIN catalog_returns cr
      ON cr.cr_refunded_customer_sk = c.c_customer_sk
     AND cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
     AND cr.cr_refunded_addr_sk = ca.ca_address_sk
    LEFT JOIN date_dim d3
      ON cr.cr_returned_date_sk = d3.d_date_sk
    LEFT JOIN web_returns wr
      ON wr.wr_refunded_customer_sk = c.c_customer_sk
     AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
     AND wr.wr_refunded_addr_sk = ca.ca_address_sk
    LEFT JOIN date_dim d4
      ON wr.wr_returned_date_sk = d4.d_date_sk
    WHERE d1.d_year = 2000                    -- filter 1: sales in 2000
      AND ca.ca_state = 'TX'                  -- filter 2: customers in Texas
      AND cd.cd_gender = 'M'                  -- filter 3: male customers
      AND (sr.sr_fee > 50 OR cr.cr_return_tax > 20)   -- filter 4 & 5: high fees or taxes
      AND EXISTS (                             -- semi‑join to web_page (table 9)
            SELECT 1
            FROM web_page wp
            WHERE wp.wp_web_page_sk = wr.wr_web_page_sk
              AND wp.wp_char_count > 1500   -- additional predicate on web_page
        )
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    SUM(COALESCE(cr_return_amount, 0) + COALESCE(sr_return_amt, 0) + COALESCE(wr_return_amt, 0)) AS total_return_amount,
    ROW_NUMBER() OVER (
        ORDER BY SUM(COALESCE(cr_return_amount, 0) + COALESCE(sr_return_amt, 0) + COALESCE(wr_return_amt, 0)) DESC
    ) AS return_rank
FROM base
GROUP BY c_customer_id, c_first_name, c_last_name
ORDER BY total_return_amount DESC
LIMIT 100
