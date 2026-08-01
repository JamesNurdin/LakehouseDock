WITH sampled_returns AS (
    SELECT *
    FROM tpcds.catalog_returns
    TABLESAMPLE BERNOULLI (10)   -- sample 10% of rows
),
joined_data AS (
    SELECT
        cr.cr_returned_date_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_refunded_cash,
        cr.cr_returning_customer_sk,
        cr.cr_refunded_customer_sk,
        cr.cr_returning_cdemo_sk,
        cr.cr_refunded_cdemo_sk,
        cust.c_salutation,
        cust.c_last_review_date,
        cust.c_first_sales_date_sk,
        dem.cd_gender,
        dem.cd_dep_college_count,
        dem.cd_dep_employed_count
    FROM sampled_returns cr
    LEFT JOIN tpcds.customer cust
        ON cr.cr_returning_customer_sk = cust.c_customer_sk
    LEFT JOIN tpcds.customer_demographics dem
        ON cr.cr_returning_cdemo_sk = dem.cd_demo_sk
    WHERE
        cr.cr_return_amount > 50                      -- predicate 1
        AND dem.cd_dep_college_count >= 2             -- predicate 2
        AND cust.c_salutation IN ('Mrs.', 'Dr.', 'Mr.') -- predicate 3
),
agg1 AS (
    SELECT
        c_salutation,
        cd_gender,
        CASE
            WHEN cr_return_amount > 100 THEN 'High'
            WHEN cr_return_amount BETWEEN 50 AND 100 THEN 'Medium'
            ELSE 'Low'
        END AS amount_category,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt,
        AVG(cr_refunded_cash) AS avg_refunded_cash,
        SUM(cr_return_quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY c_salutation ORDER BY SUM(cr_return_amount) DESC) AS salutation_rank
    FROM joined_data
    GROUP BY
        c_salutation,
        cd_gender,
        CASE
            WHEN cr_return_amount > 100 THEN 'High'
            WHEN cr_return_amount BETWEEN 50 AND 100 THEN 'Medium'
            ELSE 'Low'
        END
),
agg2 AS (
    SELECT
        a.*, 
        lt.total_gender_return_amount
    FROM agg1 a
    LEFT JOIN LATERAL (
        SELECT SUM(total_return_amount) AS total_gender_return_amount
        FROM agg1 a2
        WHERE a2.cd_gender = a.cd_gender
    ) lt ON TRUE
    WHERE a.return_cnt >= 5
)
SELECT
    c_salutation,
    cd_gender,
    amount_category,
    SUM(total_return_amount) AS sum_return_amount,
    SUM(return_cnt) AS sum_return_cnt,
    AVG(avg_refunded_cash) AS avg_refunded_cash_overall,
    SUM(total_quantity) AS sum_quantity,
    MAX(salutation_rank) AS max_rank,
    MAX(total_gender_return_amount) AS gender_total,
    CASE
        WHEN SUM(total_return_amount) > MAX(total_gender_return_amount) THEN 'Above Gender Avg'
        ELSE 'Below Gender Avg'
    END AS performance_flag,
    (SELECT COUNT(*) FROM sampled_returns) AS sampled_rows  -- scalar subquery
FROM agg2
GROUP BY ROLLUP (c_salutation, cd_gender, amount_category)
HAVING SUM(total_return_amount) > 0
ORDER BY c_salutation NULLS LAST,
         cd_gender NULLS LAST,
         amount_category NULLS LAST
