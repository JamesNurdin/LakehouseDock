WITH base_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_birth_country,
        c.c_birth_year,
        c.c_current_cdemo_sk,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_dep_count
    FROM tpcds.customer c
    JOIN tpcds.customer_demographics cd
        ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT
    birth_country,
    birth_year,
    cust_cnt,
    avg_purchase_est
FROM (
    SELECT
        bc.c_birth_country AS birth_country,
        bc.c_birth_year AS birth_year,
        COUNT(*) AS cust_cnt,
        AVG(bc.cd_purchase_estimate) AS avg_purchase_est
    FROM base_customers bc
    WHERE bc.cd_marital_status = 'M'
      AND bc.c_birth_country IN ('MONACO', 'KOREA', 'VANUATU')
      AND NOT EXISTS (
          SELECT 1
          FROM tpcds.customer_demographics cd2
          WHERE cd2.cd_demo_sk = bc.c_current_cdemo_sk
            AND cd2.cd_dep_count > 5
      )
    GROUP BY bc.c_birth_country, bc.c_birth_year
    HAVING COUNT(*) > 10

    UNION ALL

    SELECT
        bc.c_birth_country AS birth_country,
        bc.c_birth_year AS birth_year,
        COUNT(*) AS cust_cnt,
        AVG(bc.cd_purchase_estimate) AS avg_purchase_est
    FROM base_customers bc
    WHERE bc.cd_marital_status = 'S'
      AND bc.cd_dep_count <= 2
    GROUP BY bc.c_birth_country, bc.c_birth_year
    HAVING COUNT(*) >= 5
) AS combined
ORDER BY birth_country ASC, cust_cnt DESC
LIMIT 100
