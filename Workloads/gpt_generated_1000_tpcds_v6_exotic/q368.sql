WITH agg_returns AS (
    SELECT
        c.c_customer_sk,
        c.c_birth_month AS birth_month,
        hd.hd_dep_count AS dep_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt,
        CASE
            WHEN ib.ib_upper_bound > 50000 THEN 'high_income'
            WHEN ib.ib_upper_bound BETWEEN 20000 AND 50000 THEN 'mid_income'
            ELSE 'low_income'
        END AS income_category
    FROM web_returns wr
    JOIN customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE wr.wr_return_amt > 20.0
      AND wr.wr_return_tax BETWEEN 20.0 AND 100.0
      AND c.c_birth_month IN (1, 3, 4, 8, 9)
      AND hd.hd_dep_count >= 3
      AND ib.ib_lower_bound >= 10000
    GROUP BY
        c.c_customer_sk,
        c.c_birth_month,
        hd.hd_dep_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        CASE
            WHEN ib.ib_upper_bound > 50000 THEN 'high_income'
            WHEN ib.ib_upper_bound BETWEEN 20000 AND 50000 THEN 'mid_income'
            ELSE 'low_income'
        END
)
SELECT
    birth_month,
    dep_count,
    income_category,
    SUM(total_return_amt) AS sum_return_amt,
    AVG(total_net_loss) AS avg_net_loss,
    COUNT(*) AS num_customers
FROM agg_returns ar
WHERE EXISTS (
    SELECT 1
    FROM web_returns wr2
    WHERE wr2.wr_returning_customer_sk = ar.c_customer_sk
      AND wr2.wr_return_quantity > 1
)
GROUP BY ROLLUP (birth_month, dep_count, income_category)
HAVING SUM(total_return_amt) > 1000
ORDER BY
    birth_month NULLS LAST,
    dep_count DESC,
    sum_return_amt DESC
LIMIT 100
