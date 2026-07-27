WITH refunded_returns AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_refunded_customer_sk,
        cr.cr_refunded_hdemo_sk,
        c.c_birth_year,
        c.c_birth_month,
        c.c_birth_day,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        ib.ib_lower_bound AS income_lower_bound,
        ib.ib_upper_bound AS income_upper_bound
    FROM catalog_returns cr
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cr.cr_return_amount > 100
      AND cr.cr_return_quantity >= 2
      AND c.c_birth_year BETWEEN 1960 AND 1985
      AND hd.hd_buy_potential = '>10000'
      AND ib.ib_upper_bound <= 150000
)
SELECT
    fr.income_lower_bound,
    fr.income_upper_bound,
    fr.hd_buy_potential,
    COUNT(*) AS return_cnt,
    SUM(fr.cr_return_amount) AS total_return_amount,
    AVG(fr.cr_return_amount) AS avg_return_amount,
    MIN(fr.cr_return_amount) AS min_return_amount,
    MAX(fr.cr_return_amount) AS max_return_amount
FROM refunded_returns fr
WHERE EXISTS (
    SELECT 1
    FROM customer c2
    WHERE c2.c_customer_sk = fr.cr_refunded_customer_sk
      AND c2.c_email_address LIKE '%@example.com'
)
GROUP BY fr.income_lower_bound, fr.income_upper_bound, fr.hd_buy_potential
HAVING SUM(fr.cr_return_amount) > (
    SELECT AVG(cr_return_amount)
    FROM catalog_returns
    WHERE cr_return_amount IS NOT NULL
)
ORDER BY total_return_amount DESC
LIMIT 100
