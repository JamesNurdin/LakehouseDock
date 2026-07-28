/*
  Goal: Compare total return amounts by customer county across catalog and store returns, flag counties with above‑average returns, and list the top results.
*/
WITH county_returns AS (
    -- Catalog returns per county
    SELECT
        ca.ca_county AS ca_county,
        SUM(cr.cr_return_amount) AS return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE cp.cp_type = 'monthly'
      AND cp.cp_start_date_sk BETWEEN 2450900 AND 2451000
    GROUP BY ca.ca_county

    UNION ALL

    -- Store returns per county
    SELECT
        ca.ca_county AS ca_county,
        SUM(sr.sr_return_amt) AS return_amount,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2450900 AND 2451000
    GROUP BY ca.ca_county
),
aggregated AS (
    SELECT
        ca_county AS county,
        SUM(return_amount) AS total_return_amount,
        SUM(return_cnt) AS total_return_cnt
    FROM county_returns
    GROUP BY ca_county
)
SELECT
    a.county,
    a.total_return_amount,
    a.total_return_cnt,
    CASE
        WHEN a.total_return_amount > (
            SELECT AVG(b.total_return_amount) FROM aggregated b
        ) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS return_category
FROM aggregated a
ORDER BY a.total_return_amount DESC
LIMIT 100
