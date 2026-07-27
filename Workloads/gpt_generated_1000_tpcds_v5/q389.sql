WITH filtered_returns AS (
    SELECT
        sr.sr_customer_sk,
        sr.sr_returned_date_sk,
        sr.sr_return_amt,
        sr.sr_fee,
        sr.sr_store_credit,
        sr.sr_reversed_charge,
        sr.sr_net_loss
    FROM store_returns sr
    WHERE sr.sr_return_amt > 150.00                      -- predicate 1
      AND sr.sr_fee BETWEEN 15 AND 80                    -- predicate 2
      AND sr.sr_store_credit < 300.00                    -- predicate 3
      AND sr.sr_reversed_charge > 0.10                  -- predicate 4
      AND sr.sr_return_quantity >= 2                    -- predicate 5
      AND sr.sr_return_amt_inc_tax IS NOT NULL          -- predicate 6
)
SELECT
    c.c_customer_id,
    COALESCE(d.d_date, DATE '1970-01-01') AS return_date,
    d.d_week_seq,
    SUM(fr.sr_return_amt)           AS total_return_amt,
    SUM(fr.sr_fee)                  AS total_fee,
    SUM(fr.sr_store_credit)         AS total_store_credit,
    SUM(fr.sr_reversed_charge)      AS total_reversed_charge,
    COUNT(*)                        AS return_cnt,
    RANK() OVER (PARTITION BY d.d_week_seq ORDER BY SUM(fr.sr_return_amt) DESC) AS weekly_return_rank,
    CASE
        WHEN SUM(fr.sr_return_amt) > 1000 THEN 'HIGH'
        WHEN SUM(fr.sr_return_amt) > 500  THEN 'MEDIUM'
        ELSE 'LOW'
    END AS return_category
FROM filtered_returns fr
JOIN customer c
    ON fr.sr_customer_sk = c.c_customer_sk
LEFT JOIN date_dim d
    ON fr.sr_returned_date_sk = d.d_date_sk
WHERE c.c_birth_day BETWEEN 1 AND 28                                 -- predicate 7
  AND c.c_birth_month IN (1,2,3,4,5,6)                               -- predicate 8
  AND (d.d_holiday = 'N' OR d.d_holiday IS NULL)                     -- predicate 9
  AND (d.d_week_seq IN (3,8,14,19,4) OR d.d_week_seq IS NULL)        -- predicate 10
GROUP BY
    c.c_customer_id,
    COALESCE(d.d_date, DATE '1970-01-01'),
    d.d_week_seq
HAVING SUM(fr.sr_return_amt) > 200                                 -- predicate 11
ORDER BY total_return_amt DESC
LIMIT 100
