WITH returns_summary AS (
    SELECT
        t.t_hour,
        ca.ca_state,
        c.c_birth_year,
        COUNT(*) AS return_cnt,
        SUM(sr.sr_return_amt) AS total_return_amt,
        AVG(sr.sr_return_quantity) AS avg_return_qty,
        SUM(sr.sr_refunded_cash) AS total_refunded_cash,
        COUNT(DISTINCT sr.sr_customer_sk) AS distinct_customers
    FROM store_returns sr
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    WHERE t.t_hour BETWEEN 8 AND 20
      AND c.c_birth_year BETWEEN 1950 AND 1970
      AND ca.ca_state IN ('CA', 'TX', 'NY')
    GROUP BY t.t_hour, ca.ca_state, c.c_birth_year
    HAVING COUNT(*) > 10
)
SELECT
    t_hour,
    ca_state,
    c_birth_year,
    return_cnt,
    total_return_amt,
    avg_return_qty,
    total_refunded_cash,
    distinct_customers,
    RANK() OVER (PARTITION BY t_hour ORDER BY total_return_amt DESC) AS state_year_rank
FROM returns_summary
ORDER BY t_hour, total_return_amt DESC
LIMIT 200
