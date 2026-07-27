WITH address_loss AS (
    SELECT
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        d.d_year,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE ca.ca_street_type = 'Road'
      AND d.d_year BETWEEN 2000 AND 2002
    GROUP BY ca.ca_address_sk, ca.ca_city, ca.ca_state, d.d_year
)
SELECT
    al.ca_address_sk,
    al.ca_city,
    al.ca_state,
    al.d_year,
    al.total_net_loss,
    al.return_cnt,
    CAST('refunded' AS varchar) AS address_role
FROM address_loss al
WHERE al.total_net_loss > (
    SELECT AVG(total_net_loss) FROM address_loss
)
UNION ALL
SELECT
    ca.ca_address_sk,
    ca.ca_city,
    ca.ca_state,
    d.d_year,
    SUM(wr.wr_net_loss) AS total_net_loss,
    COUNT(*) AS return_cnt,
    CAST('returning' AS varchar) AS address_role
FROM web_returns wr
JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
JOIN customer_address ca ON wr.wr_returning_addr_sk = ca.ca_address_sk
WHERE ca.ca_street_type = 'Drive'
  AND d.d_year BETWEEN 2000 AND 2002
  AND EXISTS (
        SELECT 1
        FROM customer_address ca2
        WHERE ca2.ca_state = ca.ca_state
          AND ca2.ca_city = ca.ca_city
          AND ca2.ca_street_type = 'Road'
    )
GROUP BY ca.ca_address_sk, ca.ca_city, ca.ca_state, d.d_year
HAVING SUM(wr.wr_net_loss) > (
    SELECT AVG(total_net_loss) FROM address_loss
)
ORDER BY total_net_loss DESC
LIMIT 100
