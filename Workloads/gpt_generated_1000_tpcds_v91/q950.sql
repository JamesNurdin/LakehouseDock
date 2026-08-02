WITH sampled_sales AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (5)
)
SELECT
    cd.cd_dep_employed_count,
    cd.cd_dep_college_count,
    COUNT(*) AS sales_count,
    SUM(ss.cs_net_paid_inc_ship_tax) AS total_net_paid_inc_ship_tax,
    AVG(ss.cs_net_profit) AS avg_net_profit,
    MIN(ss.cs_net_paid_inc_ship_tax) AS min_net_paid_inc_ship_tax,
    (SELECT avg(cs2.cs_net_paid_inc_ship_tax) FROM catalog_sales cs2) AS overall_avg_net_paid_inc_ship_tax
FROM sampled_sales ss
JOIN customer_demographics cd
    ON ss.cs_bill_cdemo_sk = cd.cd_demo_sk
WHERE
    ss.cs_net_paid_inc_ship_tax > 1500
    AND ss.cs_net_profit > 0
    AND ss.cs_catalog_page_sk IN (97, 172, 272)
    AND cd.cd_education_status = 'Advanced Degree'
    AND cd.cd_dep_college_count >= 2
    AND NOT EXISTS (
        SELECT 1
        FROM catalog_sales cs_ship
        JOIN customer_demographics cd_ship
            ON cs_ship.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
        WHERE cs_ship.cs_order_number = ss.cs_order_number
          AND cd_ship.cd_education_status = 'Primary'
    )
GROUP BY
    cd.cd_dep_employed_count,
    cd.cd_dep_college_count
ORDER BY total_net_paid_inc_ship_tax DESC
LIMIT 100
