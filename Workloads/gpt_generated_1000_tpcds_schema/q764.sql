WITH
  refunded_addresses AS (
    SELECT
      ca.ca_address_sk,
      ca.ca_city,
      ca.ca_state,
      SUM(wr.wr_return_amt) AS total_refund,
      COUNT(*) AS refund_cnt
    FROM web_returns wr
    JOIN customer_address ca
      ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    WHERE wr.wr_return_amt > 100
      AND ca.ca_state = 'CA'
      AND ca.ca_gmt_offset BETWEEN -5.00 AND 0.00
    GROUP BY ca.ca_address_sk, ca.ca_city, ca.ca_state
  ),
  returning_addresses AS (
    SELECT
      ca.ca_address_sk,
      ca.ca_city,
      ca.ca_state,
      SUM(wr.wr_return_amt) AS total_return,
      COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN customer_address ca
      ON wr.wr_returning_addr_sk = ca.ca_address_sk
    WHERE wr.wr_return_quantity > 1
      AND ca.ca_country = 'United States'
      AND wr.wr_return_tax > 0
    GROUP BY ca.ca_address_sk, ca.ca_city, ca.ca_state
  ),
  union_addresses AS (
    SELECT
      ca_address_sk,
      ca_city,
      ca_state,
      total_refund AS total_amount,
      refund_cnt AS cnt,
      'REFUND' AS src
    FROM refunded_addresses
    UNION
    SELECT
      ca_address_sk,
      ca_city,
      ca_state,
      total_return AS total_amount,
      return_cnt AS cnt,
      'RETURN' AS src
    FROM returning_addresses
  ),
  full_joined AS (
    SELECT
      ca.ca_address_sk,
      ca.ca_city,
      ca.ca_state,
      ca.ca_gmt_offset,
      COALESCE(ua.total_amount, 0) AS total_amount,
      COALESCE(ua.cnt, 0) AS cnt,
      CASE
        WHEN COALESCE(ua.total_amount, 0) > 1000 THEN 'HIGH'
        WHEN COALESCE(ua.total_amount, 0) > 500 THEN 'MEDIUM'
        ELSE 'LOW'
      END AS amount_category,
      (
        SELECT COUNT(*)
        FROM web_returns wr2
        WHERE wr2.wr_returning_addr_sk = ca.ca_address_sk
      ) AS returning_return_cnt,
      ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY COALESCE(ua.total_amount, 0) DESC) AS state_rank
    FROM customer_address ca
    FULL OUTER JOIN union_addresses ua
      ON ca.ca_address_sk = ua.ca_address_sk
    WHERE ca.ca_zip IS NOT NULL
      AND ca.ca_city <> ''
      AND ca.ca_gmt_offset IS NOT NULL
  )
SELECT
  ca_address_sk,
  ca_city,
  ca_state,
  ca_gmt_offset,
  total_amount,
  cnt,
  amount_category,
  returning_return_cnt,
  state_rank
FROM full_joined
WHERE ca_address_sk IN (
  SELECT ca_address_sk
  FROM (
    SELECT ca_address_sk FROM customer_address
    EXCEPT
    SELECT wr_refunded_addr_sk FROM web_returns
  ) AS missing_refund
)
ORDER BY amount_category, total_amount DESC
LIMIT 100
