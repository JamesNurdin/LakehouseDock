WITH joined AS (
    SELECT
        sr.sr_customer_sk,
        sr.sr_return_amt,
        sr.sr_net_loss,
        c.c_birth_country,
        c.c_last_review_date,
        hd.hd_income_band_sk,
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        hd.hd_dep_count,
        hd.hd_buy_potential
    FROM store_returns sr
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE hd.hd_dep_count > 3
      AND hd.hd_buy_potential = '1001-5000'
      AND c.c_birth_country IN ('UKRAINE', 'BAHAMAS')
      AND ib.ib_lower_bound >= 90000
      AND sr.sr_return_amt > 50
      AND c.c_last_review_date > 2452300
),
agg_per_income AS (
    SELECT
        ib_income_band_sk,
        ib_lower_bound,
        ib_upper_bound,
        SUM(sr_net_loss) AS total_net_loss,
        COUNT(DISTINCT sr_customer_sk) AS distinct_customers,
        AVG(sr_return_amt) AS avg_return_amt
    FROM joined
    GROUP BY ib_income_band_sk, ib_lower_bound, ib_upper_bound
    HAVING SUM(sr_net_loss) > 0
)
SELECT
    a.ib_income_band_sk,
    a.ib_lower_bound,
    a.ib_upper_bound,
    a.total_net_loss,
    a.distinct_customers,
    a.avg_return_amt,
    RANK() OVER (ORDER BY a.total_net_loss DESC) AS loss_rank,
    (SELECT AVG(total_net_loss) FROM agg_per_income) AS avg_net_loss_all,
    (SELECT COUNT(DISTINCT c.c_customer_sk)
       FROM customer c
       JOIN household_demographics hd
         ON c.c_current_hdemo_sk = hd.hd_demo_sk
       WHERE hd.hd_income_band_sk = a.ib_income_band_sk) AS total_customers_in_band
FROM agg_per_income a
WHERE EXISTS (
    SELECT 1
    FROM household_demographics hd_ex
    JOIN customer c_ex
      ON c_ex.c_current_hdemo_sk = hd_ex.hd_demo_sk
    WHERE hd_ex.hd_income_band_sk = a.ib_income_band_sk
)
ORDER BY a.total_net_loss DESC
