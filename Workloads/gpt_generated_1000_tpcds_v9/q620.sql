WITH filtered_returns AS (
    SELECT
        wr_returned_date_sk,
        wr_return_quantity,
        wr_return_amt,
        wr_refunded_cash,
        wr_return_tax,
        wr_refunded_customer_sk,
        wr_refunded_addr_sk,
        wr_returning_addr_sk
    FROM web_returns
    WHERE wr_returned_date_sk >= 2451490
      AND wr_returned_date_sk <= 2451940
      AND wr_return_quantity > 1
      AND wr_return_amt > 50
)
SELECT
    ca_refunded.ca_state,
    CASE WHEN filtered_returns.wr_return_amt > 100 THEN 'High' ELSE 'Low' END AS return_category,
    city_suite.suite_cnt AS suite_cnt_for_city,
    SUM(filtered_returns.wr_return_amt) AS total_return_amt,
    AVG(filtered_returns.wr_refunded_cash) AS avg_refunded_cash,
    COUNT(DISTINCT filtered_returns.wr_refunded_customer_sk) AS distinct_refunded_customers,
    MIN(filtered_returns.wr_return_tax) AS min_return_tax,
    MAX(filtered_returns.wr_return_tax) AS max_return_tax,
    COUNT(*) AS total_returns
FROM filtered_returns
JOIN customer_address ca_refunded
    ON filtered_returns.wr_refunded_addr_sk = ca_refunded.ca_address_sk
JOIN customer_address ca_returning
    ON filtered_returns.wr_returning_addr_sk = ca_returning.ca_address_sk
CROSS JOIN LATERAL (
    SELECT COUNT(*) AS suite_cnt FROM (
        SELECT DISTINCT ca_inner.ca_suite_number
        FROM customer_address ca_inner
        WHERE ca_inner.ca_city = ca_refunded.ca_city
    ) d
) AS city_suite
WHERE ca_refunded.ca_suite_number = 'Suite A   '
  AND ca_refunded.ca_state = 'CA'
GROUP BY
    ca_refunded.ca_state,
    CASE WHEN filtered_returns.wr_return_amt > 100 THEN 'High' ELSE 'Low' END,
    city_suite.suite_cnt
ORDER BY total_return_amt DESC
LIMIT 100
