WITH sr_agg AS (
    SELECT
        sr_customer_sk,
        COUNT(*) AS returns_cnt,
        SUM(sr_return_amt) AS total_return_amt,
        SUM(sr_net_loss) AS total_net_loss,
        MAX(sr_return_amt) AS max_return_amt
    FROM store_returns
    WHERE sr_fee > 10.00
      AND sr_reversed_charge < 500.00
      AND sr_return_quantity >= 1
    GROUP BY sr_customer_sk
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    sr.returns_cnt,
    sr.total_return_amt,
    CASE
        WHEN sr.total_net_loss > 1000 THEN 'HIGH_LOSS'
        ELSE 'NORMAL'
    END AS loss_category,
    (
        SELECT SUM(sr2.sr_return_amt)
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = c.c_customer_sk
    ) AS total_return_amt_all,
    ROW_NUMBER() OVER (
        PARTITION BY CASE WHEN c.c_birth_day <= 15 THEN 'EARLY' ELSE 'LATE' END
        ORDER BY sr.total_return_amt DESC
    ) AS rn
FROM sr_agg sr
JOIN customer c
    ON sr.sr_customer_sk = c.c_customer_sk
WHERE c.c_birth_month = 5
  AND c.c_last_review_date >= 2452500
  AND c.c_preferred_cust_flag = 'Y'
  AND EXISTS (
        SELECT 1
        FROM store_returns sr3
        WHERE sr3.sr_customer_sk = c.c_customer_sk
          AND sr3.sr_fee > 20.00
    )
ORDER BY rn ASC
LIMIT 100
