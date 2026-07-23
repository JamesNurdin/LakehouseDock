WITH filtered AS (
    SELECT
        sr.sr_customer_sk,
        sr.sr_return_amt,
        sr.sr_return_tax,
        c.c_birth_month,
        c.c_first_sales_date_sk,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM store_returns sr
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE sr.sr_return_amt > 100.00
      AND sr.sr_return_tax BETWEEN 1.00 AND 30.00
      AND c.c_birth_month = 6
      AND c.c_first_sales_date_sk BETWEEN 2451500 AND 2451800
      AND ib.ib_lower_bound >= 150001
)
SELECT
    ib_lower_bound,
    ib_upper_bound,
    hd_buy_potential,
    c_birth_month,
    COUNT(DISTINCT sr_customer_sk) AS distinct_customers,
    SUM(sr_return_amt) AS total_return_amount,
    AVG(sr_return_tax) AS avg_return_tax,
    MIN(sr_return_amt) AS min_return_amount,
    MAX(sr_return_amt) AS max_return_amount
FROM filtered
GROUP BY ib_lower_bound, ib_upper_bound, hd_buy_potential, c_birth_month
ORDER BY total_return_amount DESC
LIMIT 100
