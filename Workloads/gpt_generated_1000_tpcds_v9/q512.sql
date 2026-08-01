/* goal: Compare total return amount, count of returns, and average fee per customer address for catalog and web returns, preserving addresses with no matching returns via full outer joins, and combine the two result sets with a UNION ALL. */
WITH catalog_agg AS (
    SELECT
        ca.ca_address_sk,
        ca.ca_city,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(cr.cr_order_number) AS return_cnt,
        AVG(cr.cr_fee) AS avg_fee,
        'catalog' AS source
    FROM catalog_returns cr
    FULL OUTER JOIN customer_address ca
        ON cr.cr_refunded_addr_sk = ca.ca_address_sk
        AND cr.cr_fee > 5
        AND cr.cr_returning_customer_sk > 5000000
    GROUP BY ca.ca_address_sk, ca.ca_city
),
web_agg AS (
    SELECT
        ca.ca_address_sk,
        ca.ca_city,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(wr.wr_order_number) AS return_cnt,
        AVG(wr.wr_fee) AS avg_fee,
        'web' AS source
    FROM web_returns wr
    FULL OUTER JOIN customer_address ca
        ON wr.wr_refunded_addr_sk = ca.ca_address_sk
        AND wr.wr_fee > 5
        AND wr.wr_returning_customer_sk > 2000000
    GROUP BY ca.ca_address_sk, ca.ca_city
)
SELECT
    ca_address_sk,
    ca_city,
    total_return_amount,
    return_cnt,
    avg_fee,
    source
FROM catalog_agg
UNION ALL
SELECT
    ca_address_sk,
    ca_city,
    total_return_amount,
    return_cnt,
    avg_fee,
    source
FROM web_agg
ORDER BY total_return_amount DESC
LIMIT 100
