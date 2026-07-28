/* goal: Compute total and average net loss per income band for male customers with dependent counts > 1 and return fees >= 10, aggregating first by customer then by income band, ranking bands by total loss */
WITH cust_returns AS (
    SELECT
        c.c_customer_id            AS customer_id,
        c.c_birth_month,
        c.c_salutation,
        hd.hd_income_band_sk       AS income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        SUM(sr.sr_net_loss)        AS customer_net_loss,
        COUNT(*)                  AS return_cnt,
        AVG(sr.sr_fee)            AS avg_fee
    FROM store_returns sr
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON sr.sr_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE c.c_birth_month BETWEEN 1 AND 12               -- predicate 1
      AND c.c_salutation = 'Mr.'                         -- predicate 2
      AND hd.hd_dep_count > 1                            -- predicate 3
      AND sr.sr_fee >= 10.0                               -- predicate 4
    GROUP BY
        c.c_customer_id,
        c.c_birth_month,
        c.c_salutation,
        hd.hd_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
)
SELECT
    income_band_sk,
    ib_lower_bound   AS lower_bound,
    ib_upper_bound   AS upper_bound,
    COUNT(customer_id)            AS num_customers,
    SUM(customer_net_loss)        AS band_total_loss,
    AVG(customer_net_loss)        AS avg_customer_loss,
    SUM(return_cnt)               AS total_returns,
    AVG(avg_fee)                  AS avg_fee_across_customers,
    ROW_NUMBER() OVER (ORDER BY SUM(customer_net_loss) DESC) AS loss_rank
FROM cust_returns
WHERE customer_net_loss > 0
GROUP BY
    income_band_sk,
    ib_lower_bound,
    ib_upper_bound
HAVING COUNT(customer_id) >= 3
ORDER BY loss_rank
LIMIT 100
