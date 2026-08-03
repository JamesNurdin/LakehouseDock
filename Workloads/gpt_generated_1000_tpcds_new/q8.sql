WITH intersected_addresses AS (
    SELECT ca_address_sk
    FROM customer_address
    WHERE regexp_like(ca_suite_number, '^Suite [0-9]+$')
      AND ca_location_type LIKE '%family%'
    INTERSECT
    SELECT ca_address_sk
    FROM customer_address
    WHERE ca_city LIKE 'San%'
)
SELECT
    td.t_hour,
    td.t_am_pm,
    ca.ca_suite_number,
    regexp_extract(ca.ca_suite_number, '(\\d+)', 1) AS suite_number,
    COUNT(wr.wr_order_number) AS returns_cnt,
    SUM(wr.wr_net_loss) AS total_net_loss,
    AVG(wr.wr_account_credit) AS avg_account_credit
FROM web_returns wr
JOIN time_dim td
  ON wr.wr_returned_time_sk = td.t_time_sk
JOIN customer_address ca
  ON wr.wr_returning_addr_sk = ca.ca_address_sk
JOIN intersected_addresses ia
  ON ca.ca_address_sk = ia.ca_address_sk
WHERE wr.wr_return_amt > 100
GROUP BY
    td.t_hour,
    td.t_am_pm,
    ca.ca_suite_number,
    regexp_extract(ca.ca_suite_number, '(\\d+)', 1)
ORDER BY total_net_loss DESC
LIMIT 100
