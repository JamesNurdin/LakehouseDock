WITH intersected AS (
    (
        SELECT DISTINCT c.c_customer_id
        FROM tpcds.customer c TABLESAMPLE BERNOULLI (10)
        JOIN tpcds.store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
        JOIN tpcds.household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
        WHERE hd.hd_dep_count >= 2
          AND c.c_salutation = 'Mr.'
          AND c.c_first_sales_date_sk BETWEEN 2450391 AND 2451825
    )
    INTERSECT
    (
        SELECT DISTINCT c.c_customer_id
        FROM tpcds.customer c
        JOIN tpcds.store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
        JOIN tpcds.household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
        JOIN tpcds.income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        WHERE ib.ib_lower_bound >= 100000
          AND sr.sr_return_amt_inc_tax > 500
    )
)
SELECT
    i.c_customer_id,
    ROW_NUMBER() OVER (ORDER BY i.c_customer_id) AS row_num
FROM intersected i
LIMIT 100
