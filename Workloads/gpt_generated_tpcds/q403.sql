WITH refunded_returns AS (
    SELECT
        cr.cr_return_quantity,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_reason_sk,
        cust.c_birth_year,
        addr.ca_state,
        addr.ca_country,
        addr.ca_gmt_offset
    FROM catalog_returns cr
    JOIN customer cust
        ON cr.cr_refunded_customer_sk = cust.c_customer_sk
    JOIN customer_address addr
        ON cr.cr_refunded_addr_sk = addr.ca_address_sk
)
SELECT
    ca_state,
    cr_reason_sk,
    COUNT(*) AS return_count,
    SUM(cr_return_quantity) AS total_quantity,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(cr_net_loss) AS total_net_loss,
    AVG(cr_return_amount) AS avg_return_amount,
    MIN(c_birth_year) AS youngest_birth_year,
    MAX(c_birth_year) AS oldest_birth_year
FROM refunded_returns
GROUP BY ca_state, cr_reason_sk
HAVING SUM(cr_net_loss) > 0
ORDER BY total_net_loss DESC
LIMIT 10
