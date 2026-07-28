WITH catalog_sub AS (
    SELECT
        d.d_year,
        ca.ca_country,
        SUM(cr.cr_return_amount) AS total_return_amount,
        CASE WHEN SUM(cr.cr_return_amount) > 10000 THEN 'High' ELSE 'Low' END AS return_category
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2000
    GROUP BY d.d_year, ca.ca_country
    HAVING SUM(cr.cr_return_amount) > 0
),
store_sub AS (
    SELECT
        d.d_year,
        ca.ca_country,
        SUM(sr.sr_return_amt) AS total_return_amount,
        CASE WHEN SUM(sr.sr_return_amt) > 10000 THEN 'High' ELSE 'Low' END AS return_category
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE d.d_year = 2000
    GROUP BY d.d_year, ca.ca_country
    HAVING SUM(sr.sr_return_amt) > 0
)
SELECT *
FROM catalog_sub
UNION ALL
SELECT *
FROM store_sub
ORDER BY d_year, total_return_amount DESC
LIMIT 100
