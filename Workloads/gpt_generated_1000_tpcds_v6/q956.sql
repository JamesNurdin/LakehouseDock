WITH cust_returns AS (
    SELECT
        sr.sr_customer_sk,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_return_tax) AS total_tax,
        COUNT(*) AS return_cnt,
        AVG(sr.sr_return_ship_cost) AS avg_ship_cost
    FROM store_returns sr
    WHERE sr.sr_return_tax > 2.0
      AND sr.sr_return_ship_cost > 0
      AND sr.sr_fee BETWEEN 30 AND 80
    GROUP BY sr.sr_customer_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cr.total_return_amt,
    cr.total_tax,
    cr.return_cnt,
    RANK() OVER (ORDER BY cr.total_return_amt DESC) AS return_amount_rank,
    CASE
        WHEN cr.total_tax > 5 THEN 'High Tax'
        ELSE 'Low Tax'
    END AS tax_category
FROM cust_returns cr
JOIN customer c
    ON cr.sr_customer_sk = c.c_customer_sk
WHERE c.c_birth_day IN (1, 9, 18)
  AND c.c_current_addr_sk > 500000
  AND EXISTS (
      SELECT 1
      FROM store_returns sr2
      WHERE sr2.sr_customer_sk = c.c_customer_sk
        AND sr2.sr_return_amt_inc_tax > 100
        AND sr2.sr_return_quantity >= 1
  )
ORDER BY cr.total_return_amt DESC
LIMIT 100
