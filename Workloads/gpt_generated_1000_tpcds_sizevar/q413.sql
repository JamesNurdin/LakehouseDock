WITH address_parts AS (
    SELECT ca_address_sk,
           ca_state,
           ca_city,
           ARRAY[ca_state, ca_city] AS parts
    FROM customer_address
),
high_returns AS (
    SELECT wr_returning_addr_sk AS addr_sk,
           SUM(wr_return_amt) AS total_return
    FROM web_returns
    GROUP BY wr_returning_addr_sk
    HAVING SUM(wr_return_amt) > 1000
),
low_returns AS (
    SELECT wr_returning_addr_sk AS addr_sk,
           SUM(wr_return_amt) AS total_return
    FROM web_returns
    GROUP BY wr_returning_addr_sk
    HAVING SUM(wr_return_amt) <= 1000
),
target_addresses AS (
    SELECT addr_sk FROM high_returns
    EXCEPT
    SELECT addr_sk FROM low_returns
),
joined_data AS (
    SELECT d.d_year,
           d.d_month_seq,
           ca_ret.ca_state,
           ca_ret.ca_city,
           r.r_reason_desc,
           t.t_hour,
           wr.wr_return_amt,
           wr.wr_return_quantity,
           ca_ret.ca_address_sk,
           ua.address_element,
           wr.wr_reason_sk
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer_address ca_ret
        ON wr.wr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN address_parts ap
        ON ca_ret.ca_address_sk = ap.ca_address_sk
    CROSS JOIN UNNEST(ap.parts) AS ua(address_element)
    WHERE d.d_year = 2001
      AND ca_ret.ca_state = 'CA'
      AND r.r_reason_desc LIKE '%damaged%'
      AND wr.wr_returning_addr_sk IN (SELECT addr_sk FROM target_addresses)
)
SELECT d_year,
       d_month_seq,
       ca_state,
       ca_city,
       r_reason_desc,
       t_hour,
       SUM(wr_return_amt) AS total_return_amount,
       COUNT(*) AS return_count,
       ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY SUM(wr_return_amt) DESC) AS rn_state,
       DENSE_RANK() OVER (ORDER BY SUM(wr_return_amt) DESC) AS dr_global,
       (SELECT SUM(wr2.wr_return_amt)
        FROM web_returns wr2
        WHERE wr2.wr_reason_sk = joined_data.wr_reason_sk) AS total_amount_same_reason,
       address_element
FROM joined_data
GROUP BY d_year,
         d_month_seq,
         ca_state,
         ca_city,
         r_reason_desc,
         t_hour,
         address_element,
         wr_reason_sk
ORDER BY total_return_amount DESC
LIMIT 100
