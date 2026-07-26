WITH combined_returns AS (
    SELECT cr.cr_refunded_addr_sk AS addr_sk,
           cr.cr_return_amt_inc_tax AS return_amount
    FROM catalog_returns cr
    UNION ALL
    SELECT wr.wr_refunded_addr_sk AS addr_sk,
           wr.wr_return_amt_inc_tax AS return_amount
    FROM web_returns wr
),
address_returns AS (
    SELECT
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        SUM(cr.return_amount) AS total_return_amount
    FROM combined_returns cr
    JOIN customer_address ca ON cr.addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_address_id, ca.ca_city, ca.ca_state
),
sales_by_address AS (
    SELECT
        ca.ca_address_id,
        ca.ca_city,
        ca.ca_state,
        SUM(ss.ss_net_paid) AS total_sales_amount
    FROM store_sales ss
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    GROUP BY ca.ca_address_id, ca.ca_city, ca.ca_state
)
SELECT
    ar.ca_address_id,
    ar.ca_city,
    ar.ca_state,
    ar.total_return_amount,
    sb.total_sales_amount,
    CASE
        WHEN ar.total_return_amount > 1000 THEN 'High'
        WHEN ar.total_return_amount > 500 THEN 'Medium'
        ELSE 'Low'
    END AS return_category,
    DENSE_RANK() OVER (ORDER BY ar.total_return_amount DESC) AS return_rank
FROM address_returns ar
LEFT JOIN sales_by_address sb
    ON ar.ca_address_id = sb.ca_address_id
    AND ar.ca_city = sb.ca_city
    AND ar.ca_state = sb.ca_state
WHERE ar.total_return_amount > 0
ORDER BY return_rank
LIMIT 10
