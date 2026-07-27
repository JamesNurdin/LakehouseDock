WITH customer_returns AS (
    SELECT
        c.c_customer_sk,
        concat(c.c_first_name, ' ', c.c_last_name) AS full_name,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(DISTINCT sr.sr_reason_sk) AS distinct_reason_cnt
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)price')
      AND c.c_last_name LIKE 'B%'
      AND ib.ib_lower_bound > 50000
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
)
SELECT
    cr.full_name,
    cr.total_net_loss,
    cr.distinct_reason_cnt,
    (
        SELECT array_agg(DISTINCT r2.r_reason_desc)
        FROM store_returns sr2
        JOIN reason r2 ON sr2.sr_reason_sk = r2.r_reason_sk
        WHERE sr2.sr_customer_sk = cr.c_customer_sk
          AND regexp_like(r2.r_reason_desc, '(?i)price')
    ) AS price_related_reasons,
    (
        SELECT COUNT(*)
        FROM store_sales ss
        WHERE ss.ss_customer_sk = cr.c_customer_sk
    ) AS total_sales_transactions
FROM customer_returns cr
WHERE cr.total_net_loss > (
    SELECT avg(customer_loss)
    FROM (
        SELECT SUM(sr3.sr_net_loss) AS customer_loss
        FROM store_returns sr3
        GROUP BY sr3.sr_customer_sk
    ) t
)
ORDER BY cr.total_net_loss DESC
LIMIT 100
