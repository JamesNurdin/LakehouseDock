WITH filtered AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_first_sales_date_sk,
        hd.hd_buy_potential,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ROW_NUMBER() OVER (
            PARTITION BY ib.ib_lower_bound, ib.ib_upper_bound
            ORDER BY c.c_first_sales_date_sk DESC
        ) AS sales_rank
    FROM tpcds.customer c
    JOIN tpcds.household_demographics hd
        ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND c.c_birth_year BETWEEN 1970 AND 1990
      AND hd.hd_vehicle_count >= 1
      AND hd.hd_buy_potential IN ('1001-5000', '501-1000')
      AND ib.ib_lower_bound >= 30001
      AND ib.ib_upper_bound <= 130000
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    hd_buy_potential,
    hd_vehicle_count,
    ib_lower_bound,
    ib_upper_bound,
    sales_rank
FROM filtered
WHERE sales_rank <= 10
ORDER BY ib_lower_bound, sales_rank
LIMIT 100
