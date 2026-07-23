WITH agg_refunded AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        c.c_birth_month,
        sum(cr.cr_return_amount) AS sum_total_return_amount,
        sum(cr.cr_return_quantity) AS sum_total_quantity,
        count(*) AS sum_return_count,
        avg(cr.cr_return_amount) AS avg_return_amount
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE cr.cr_call_center_sk IN (7, 14)
      AND cr.cr_reason_sk NOT IN (53, 61)
      AND cd.cd_dep_count >= 1
      AND cd.cd_dep_college_count <= 4
      AND c.c_email_address LIKE '%@%.edu'
    GROUP BY cd.cd_gender, cd.cd_marital_status, c.c_birth_month
),
agg_returning AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        c.c_birth_month,
        sum(cr.cr_return_amount) AS sum_total_return_amount,
        sum(cr.cr_return_quantity) AS sum_total_quantity,
        count(*) AS sum_return_count,
        avg(cr.cr_return_amount) AS avg_return_amount
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_returning_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cr.cr_returning_cdemo_sk = cd.cd_demo_sk
    WHERE cr.cr_call_center_sk IN (26, 37)
      AND cr.cr_reason_sk NOT IN (2, 47)
      AND cd.cd_dep_employed_count >= 0
      AND c.c_birth_day = 6
    GROUP BY cd.cd_gender, cd.cd_marital_status, c.c_birth_month
),
combined AS (
    SELECT
        'refunded' AS return_type,
        cd_gender,
        cd_marital_status,
        c_birth_month,
        sum_total_return_amount,
        sum_total_quantity,
        sum_return_count,
        avg_return_amount
    FROM agg_refunded
    UNION ALL
    SELECT
        'returning' AS return_type,
        cd_gender,
        cd_marital_status,
        c_birth_month,
        sum_total_return_amount,
        sum_total_quantity,
        sum_return_count,
        avg_return_amount
    FROM agg_returning
)
SELECT
    return_type,
    cd_gender,
    cd_marital_status,
    c_birth_month,
    sum_total_return_amount,
    sum_total_quantity,
    sum_return_count,
    avg_return_amount
FROM combined
WHERE sum_total_return_amount > (SELECT avg(sum_total_return_amount) FROM combined)
ORDER BY sum_total_return_amount DESC
LIMIT 100
