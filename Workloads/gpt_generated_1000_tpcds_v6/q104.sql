WITH returning_condo AS (
    SELECT
        wr.wr_order_number AS order_number,
        wr.wr_return_amt AS return_amt,
        wr.wr_net_loss AS net_loss,
        r.r_reason_desc AS reason_desc,
        ca.ca_city AS city,
        ca.ca_state AS state
    FROM web_returns wr
    JOIN customer_address ca
        ON wr.wr_returning_addr_sk = ca.ca_address_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE ca.ca_location_type = 'condo'
      AND wr.wr_return_tax > 5.00
),
refunded_apartment AS (
    SELECT
        wr.wr_order_number AS order_number,
        wr.wr_return_amt AS return_amt,
        wr.wr_net_loss AS net_loss,
        r.r_reason_desc AS reason_desc,
        ca.ca_city AS city,
        ca.ca_state AS state
    FROM web_returns wr
    JOIN customer_address ca
        ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE ca.ca_location_type = 'apartment'
      AND wr.wr_return_tax < 10.00
)
SELECT DISTINCT
    order_number,
    return_amt,
    net_loss,
    reason_desc,
    city,
    state
FROM (
    SELECT * FROM returning_condo
    UNION ALL
    SELECT * FROM refunded_apartment
) combined
ORDER BY net_loss DESC
LIMIT 100
