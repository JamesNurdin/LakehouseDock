WITH filtered AS (
    SELECT
        sr.sr_return_amt,
        sr.sr_return_quantity,
        sr.sr_store_credit,
        s.s_state,
        s.s_store_name,
        t.t_second,
        cd.cd_education_status,
        ca.ca_state,
        ca.ca_city
    FROM store_returns sr
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    WHERE t.t_second = 5
      AND cd.cd_education_status = 'College'
      AND ca.ca_state = 'CA'
      AND sr.sr_store_credit > 100
      AND EXISTS (
          SELECT 1
          FROM store_returns sr2
          WHERE sr2.sr_customer_sk = sr.sr_customer_sk
            AND sr2.sr_return_amt > 500
      )
)
SELECT
    s_state,
    s_store_name,
    COUNT(*) AS return_cnt,
    SUM(sr_return_amt) AS total_return_amt,
    AVG(sr_return_quantity) AS avg_qty,
    CASE
        WHEN SUM(sr_return_amt) > 10000 THEN 'HIGH'
        WHEN SUM(sr_return_amt) > 5000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS return_level,
    SUM(SUM(sr_return_amt)) OVER (
        PARTITION BY s_state
        ORDER BY SUM(sr_return_amt) DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_state_return
FROM filtered
GROUP BY s_state, s_store_name
ORDER BY total_return_amt DESC
LIMIT 100
