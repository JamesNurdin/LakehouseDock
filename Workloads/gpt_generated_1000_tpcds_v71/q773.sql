WITH business_hours AS (
    SELECT t_time_sk
    FROM time_dim
    WHERE t_hour BETWEEN 8 AND 18
)
SELECT *
FROM (
    SELECT
        ca.ca_state AS customer_state,
        'Catalog' AS return_source,
        SUM(cr.cr_return_amount) AS total_return_amount,
        CASE WHEN SUM(cr.cr_return_amount) < 100 THEN 'Small' ELSE 'Large' END AS return_category
    FROM catalog_returns cr
    JOIN business_hours bh ON cr.cr_returned_time_sk = bh.t_time_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_state

    UNION ALL

    SELECT
        ca.ca_state AS customer_state,
        'Web' AS return_source,
        SUM(wr.wr_return_amt) AS total_return_amount,
        CASE WHEN SUM(wr.wr_return_amt) < 100 THEN 'Small' ELSE 'Large' END AS return_category
    FROM web_returns wr
    JOIN business_hours bh ON wr.wr_returned_time_sk = bh.t_time_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_state
) combined
ORDER BY total_return_amount DESC
LIMIT 100
