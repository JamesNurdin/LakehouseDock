WITH sales_agg AS (
    SELECT
        cd.cd_gender AS gender,
        cd.cd_education_status AS education_status,
        t.t_hour AS hour,
        SUM(ss.ss_net_paid) AS total_net_paid,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COUNT(*) AS txn_count,
        CASE
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            ELSE 'Single/Other'
        END AS marital_group
    FROM store_sales ss
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE ss.ss_net_paid > 0
    GROUP BY CUBE (cd.cd_gender, cd.cd_education_status, t.t_hour, cd.cd_marital_status)
)
SELECT
    row_number() OVER (ORDER BY total_net_paid DESC) AS row_num,
    gender,
    education_status,
    hour,
    total_net_paid,
    avg_discount,
    txn_count,
    marital_group,
    overall_avg_paid
FROM (
    SELECT
        gender,
        education_status,
        hour,
        total_net_paid,
        avg_discount,
        txn_count,
        marital_group,
        (SELECT AVG(ss_net_paid) FROM store_sales) AS overall_avg_paid
    FROM sales_agg
    WHERE gender = 'M' AND education_status = '4 yr Degree         '
    UNION ALL
    SELECT
        gender,
        education_status,
        hour,
        total_net_paid,
        avg_discount,
        txn_count,
        marital_group,
        (SELECT AVG(ss_net_paid) FROM store_sales) AS overall_avg_paid
    FROM sales_agg
    WHERE gender = 'F' AND education_status = '2 yr Degree         '
) AS combined
ORDER BY total_net_paid DESC
LIMIT 100
