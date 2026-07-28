WITH cr_agg AS (
    SELECT
        cr_returned_date_sk,
        cr_returning_hdemo_sk,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(*) AS cnt_returns
    FROM catalog_returns
    WHERE cr_return_amount > 0
    GROUP BY cr_returned_date_sk, cr_returning_hdemo_sk
)
SELECT
    d_ret.d_date,
    d_ret.d_year,
    CASE WHEN ib_returning.ib_upper_bound >= 100000 THEN 'HIGH_INCOME' ELSE 'MEDIUM_INCOME' END AS income_category,
    SUM(cr_agg.total_return_amount) AS sum_return_amount,
    COUNT(DISTINCT cr_agg.cr_returning_hdemo_sk) AS distinct_returning_demo,
    MAX((SELECT AVG(cr2.cr_return_amount)
          FROM catalog_returns cr2
          WHERE cr2.cr_returned_date_sk = d_ret.d_date_sk)) AS avg_return_amount_all,
    MAX(CASE WHEN EXISTS (
            SELECT 1
            FROM household_demographics hd2
            JOIN income_band ib2 ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
            WHERE hd2.hd_demo_sk = cr_agg.cr_returning_hdemo_sk
              AND ib2.ib_upper_bound > 150000
        ) THEN 1 ELSE 0 END) AS high_income_demo_exists
FROM cr_agg
JOIN date_dim d_ret
    ON cr_agg.cr_returned_date_sk = d_ret.d_date_sk
JOIN household_demographics hd_returning
    ON cr_agg.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN income_band ib_returning
    ON hd_returning.hd_income_band_sk = ib_returning.ib_income_band_sk
JOIN catalog_returns cr
    ON cr.cr_returned_date_sk = cr_agg.cr_returned_date_sk
   AND cr.cr_returning_hdemo_sk = cr_agg.cr_returning_hdemo_sk
JOIN customer cust_returning
    ON cr.cr_returning_customer_sk = cust_returning.c_customer_sk
JOIN date_dim d_sales
    ON cust_returning.c_first_sales_date_sk = d_sales.d_date_sk
JOIN household_demographics hd_cust_current
    ON cust_returning.c_current_hdemo_sk = hd_cust_current.hd_demo_sk
JOIN income_band ib_cust_current
    ON hd_cust_current.hd_income_band_sk = ib_cust_current.ib_income_band_sk
JOIN customer cust_refunded
    ON cr.cr_refunded_customer_sk = cust_refunded.c_customer_sk
JOIN household_demographics hd_refunded
    ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN income_band ib_refunded
    ON hd_refunded.hd_income_band_sk = ib_refunded.ib_income_band_sk
GROUP BY
    d_ret.d_date,
    d_ret.d_year,
    CASE WHEN ib_returning.ib_upper_bound >= 100000 THEN 'HIGH_INCOME' ELSE 'MEDIUM_INCOME' END
ORDER BY d_ret.d_year DESC, sum_return_amount DESC
LIMIT 100
