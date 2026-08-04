WITH demo_stats AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        cd.cd_dep_college_count,
        c.c_last_review_date,
        SUM(cd.cd_purchase_estimate) OVER (
            PARTITION BY cd.cd_gender
            ORDER BY c.c_customer_id
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS running_purchase_estimate
    FROM tpcds.customer c
    JOIN tpcds.customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_last_review_date > 2452500
)

SELECT DISTINCT
    combined.c_customer_id,
    combined.cd_gender,
    combined.cd_purchase_estimate,
    combined.cd_dep_college_count,
    combined.running_purchase_estimate
FROM (
    SELECT
        ds.c_customer_id,
        ds.cd_gender,
        ds.cd_purchase_estimate,
        ds.cd_dep_college_count,
        ds.running_purchase_estimate
    FROM demo_stats ds
    WHERE ds.cd_purchase_estimate > 5000

    UNION ALL

    SELECT
        ds.c_customer_id,
        ds.cd_gender,
        ds.cd_purchase_estimate,
        ds.cd_dep_college_count,
        ds.running_purchase_estimate
    FROM demo_stats ds
    WHERE ds.cd_dep_college_count >= 2
      AND EXISTS (
          SELECT 1
          FROM tpcds.customer c2
          WHERE c2.c_customer_id = ds.c_customer_id
            AND c2.c_preferred_cust_flag = 'Y'
      )
) AS combined
ORDER BY combined.cd_gender, combined.cd_purchase_estimate DESC
OFFSET 10 ROWS
LIMIT 100
