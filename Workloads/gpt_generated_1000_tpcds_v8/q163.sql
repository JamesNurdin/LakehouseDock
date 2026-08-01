/*
Goal: Analyze revenue and return performance by catalog department and web page type for customers in a specific GMT offset and state, focusing on a recent sales period, while excluding customers with large store returns. The query joins all eight selected tables, applies multiple selective filters, uses a Bernoulli sample, includes a LATERAL subquery, a scalar subquery, an anti‑join (NOT EXISTS), aggregates measures, and orders the final result.
*/
WITH ss_sample AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)   -- sample ~10% of rows for performance
),
customer_filtered AS (
    SELECT c.c_customer_sk, c.c_customer_id, c.c_birth_year, c.c_current_addr_sk
    FROM customer c
    WHERE c.c_birth_year BETWEEN 1950 AND 1960
)
SELECT
    cp.cp_department,
    wp.wp_type,
    ca.ca_state,
    COUNT(DISTINCT ss.ss_ticket_number) AS sales_txn_cnt,
    SUM(ss.ss_net_paid)                     AS total_sales,
    SUM(cs.cs_ext_sales_price)               AS total_catalog_sales,
    SUM(sr.sr_return_amt)                   AS total_store_returns,
    SUM(wr.wr_return_amt)                   AS total_web_returns,
    AVG(lwr.total_wr_amt)                   AS avg_customer_web_return_amt
FROM ss_sample ss
JOIN customer_filtered c
      ON ss.ss_customer_sk = c.c_customer_sk
JOIN customer_address ca
      ON ss.ss_addr_sk = ca.ca_address_sk
JOIN catalog_sales cs
      ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN store_returns sr
      ON sr.sr_ticket_number = ss.ss_ticket_number
     AND sr.sr_item_sk      = ss.ss_item_sk
JOIN web_returns wr
      ON wr.wr_returning_customer_sk = c.c_customer_sk
JOIN web_page wp
      ON wr.wr_web_page_sk = wp.wp_web_page_sk
LEFT JOIN LATERAL (
    SELECT SUM(wr2.wr_return_amt) AS total_wr_amt
    FROM web_returns wr2
    WHERE wr2.wr_returning_customer_sk = c.c_customer_sk
) lwr ON TRUE
WHERE ca.ca_gmt_offset = -5.00                           -- filter on GMT offset
  AND ca.ca_state = 'CA'                                 -- filter on state
  AND cp.cp_type = 'PROMO'                               -- only promotional catalog pages
  AND wp.wp_autogen_flag = 'N'                           -- only non‑auto‑generated web pages
  AND wp.wp_max_ad_count >= 2                            -- pages with at least 2 ads
  AND ss.ss_sold_date_sk BETWEEN 2450815 AND 2450845    -- recent sales period (surrogate dates)
  AND NOT EXISTS (                                        -- anti‑join: exclude customers with big store returns
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = c.c_customer_sk
          AND sr2.sr_return_amt > 1000
    )
GROUP BY
    cp.cp_department,
    wp.wp_type,
    ca.ca_state
ORDER BY
    total_sales DESC
LIMIT 100
