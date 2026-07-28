WITH returning_addr AS (
    SELECT
        wr.wr_returning_addr_sk,
        wr.wr_returned_date_sk,
        wr.wr_refunded_cash,
        wr.wr_account_credit,
        wr.wr_return_quantity,
        ca.ca_state,
        ca.ca_city,
        ca.ca_street_name,
        ca.ca_zip
    FROM web_returns wr
    JOIN customer_address ca
        ON wr.wr_returning_addr_sk = ca.ca_address_sk
    WHERE regexp_like(ca.ca_city, '^.* County$')
      AND ca.ca_street_name LIKE '%Park%'
)
SELECT
    ca_state,
    ca_city,
    COUNT(*) AS return_cnt,
    SUM(wr_refunded_cash) AS total_refunded_cash,
    AVG(wr_refunded_cash) AS avg_refunded_cash,
    SUM(CASE WHEN wr_refunded_cash > 500 THEN 1 ELSE 0 END) AS high_value_returns,
    CONCAT('ZIP-', ca_zip) AS zip_label
FROM returning_addr ra
WHERE ra.wr_returned_date_sk IN (
    SELECT DISTINCT wr2.wr_returned_date_sk
    FROM web_returns wr2
    WHERE wr2.wr_return_quantity > 1
)
GROUP BY ca_state, ca_city, ca_zip
ORDER BY total_refunded_cash DESC
LIMIT 100
