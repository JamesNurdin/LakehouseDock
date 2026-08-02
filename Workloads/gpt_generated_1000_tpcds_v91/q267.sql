WITH ss_agg AS (
    SELECT ss_store_sk,
           ss_customer_sk,
           SUM(ss_ext_sales_price) AS total_sales,
           COUNT(*) AS sales_transactions
    FROM store_sales
    TABLESAMPLE BERNOULLI (5)
    GROUP BY ss_store_sk, ss_customer_sk
)
SELECT
    s.s_state,
    cd.cd_gender,
    COUNT(DISTINCT c.c_customer_sk) AS num_customers,
    SUM(ss_agg.total_sales) AS total_sales_amount,
    AVG(ss_agg.total_sales) AS avg_sales_per_customer,
    MIN(ss_agg.total_sales) AS min_sales,
    MAX(ss_agg.total_sales) AS max_sales,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS transaction_count,
    (SELECT COUNT(*) FROM catalog_returns) AS overall_return_records
FROM ss_agg
JOIN store s ON ss_agg.ss_store_sk = s.s_store_sk
JOIN customer c ON ss_agg.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN catalog_returns cr ON cr.cr_refunded_customer_sk = c.c_customer_sk
WHERE
    s.s_state = 'CA'
    AND s.s_gmt_offset BETWEEN -8.00 AND -5.00
    AND c.c_birth_year = 1973
    AND c.c_preferred_cust_flag = 'Y'
    AND cd.cd_marital_status IN ('M', 'S')
    AND hd.hd_income_band_sk = 5
    AND cr.cr_return_quantity > 2
    AND ss_agg.total_sales > 500
    AND EXISTS (
        SELECT 1
        FROM catalog_returns cr_ex
        WHERE cr_ex.cr_refunded_customer_sk = c.c_customer_sk
          AND cr_ex.cr_return_amount > 300
    )
GROUP BY ROLLUP(s.s_state, cd.cd_gender)
HAVING SUM(ss_agg.total_sales) > 1000
ORDER BY s.s_state ASC NULLS LAST,
         cd.cd_gender ASC NULLS LAST,
         total_sales_amount DESC
LIMIT 100
