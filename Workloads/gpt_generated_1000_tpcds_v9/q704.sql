WITH filtered_customers AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_birth_month,
        c.c_first_sales_date_sk,
        c.c_preferred_cust_flag,
        c.c_current_hdemo_sk
    FROM tpcds.customer c
    WHERE c.c_birth_month IN (8, 10, 9)
        AND c.c_first_sales_date_sk BETWEEN 2450000 AND 2452500
        AND c.c_preferred_cust_flag = 'Y'
        AND c.c_current_hdemo_sk IS NOT NULL
)
SELECT
    fc.c_customer_id,
    COALESCE(hd.hd_buy_potential, 'No Potential') AS buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    fc.c_birth_month,
    fc.c_first_sales_date_sk,
    ROW_NUMBER() OVER (PARTITION BY hd.hd_buy_potential ORDER BY ib.ib_lower_bound DESC) AS rn_by_buy_potential,
    RANK() OVER (ORDER BY fc.c_first_sales_date_sk) AS overall_sales_rank,
    CASE
        WHEN ib.ib_lower_bound >= 100000 THEN 'High Income'
        WHEN ib.ib_lower_bound >= 50000 THEN 'Mid Income'
        ELSE 'Low Income'
    END AS income_category
FROM filtered_customers fc
LEFT OUTER JOIN tpcds.household_demographics hd
    ON fc.c_current_hdemo_sk = hd.hd_demo_sk
CROSS JOIN LATERAL (
    SELECT ib.ib_income_band_sk,
           ib.ib_lower_bound,
           ib.ib_upper_bound
    FROM tpcds.income_band ib
    WHERE ib.ib_income_band_sk = hd.hd_income_band_sk
) ib
WHERE (hd.hd_dep_count >= 1 OR hd.hd_dep_count IS NULL)
  AND (hd.hd_buy_potential IN ('>10000', '5001-10000') OR hd.hd_buy_potential IS NULL)
  AND (hd.hd_vehicle_count >= 1 OR hd.hd_vehicle_count IS NULL)
  AND ib.ib_lower_bound >= 50000
  AND ib.ib_upper_bound <= 200000
  AND NOT EXISTS (
        SELECT 1
        FROM tpcds.household_demographics hd2
        WHERE hd2.hd_demo_sk = fc.c_current_hdemo_sk
          AND hd2.hd_buy_potential = 'Unknown'
    )
ORDER BY overall_sales_rank
LIMIT 100
