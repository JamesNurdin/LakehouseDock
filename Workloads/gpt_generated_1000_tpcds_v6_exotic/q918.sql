/*
Goal: Identify top‑spending customers for lunch and dinner periods, flag each transaction as above or below the overall average net paid (including tax), rank the rows overall and per customer, and return the 100 most relevant records.
*/
WITH base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_warehouse_sk,
        cs.cs_net_paid_inc_tax,
        cs.cs_net_profit,
        c.c_customer_sk,
        c.c_birth_month,
        cd.cd_gender,
        hd.hd_income_band_sk,
        t.t_meal_time,
        t.t_shift
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE cs.cs_warehouse_sk IN (1, 6, 12)
      AND t.t_meal_time IN ('breakfast', 'lunch', 'dinner')
      AND t.t_shift = 'first'
      AND c.c_birth_month BETWEEN 1 AND 12
      AND cd.cd_gender = 'M'
      AND hd.hd_income_band_sk BETWEEN 2 AND 4
      AND cs.cs_net_paid_inc_tax > 500
),
avg_paid AS (
    SELECT avg(cs_net_paid_inc_tax) AS avg_val FROM base
)
SELECT *
FROM (
    SELECT
        b.c_customer_sk,
        b.c_birth_month,
        b.cd_gender,
        b.hd_income_band_sk,
        b.t_meal_time,
        b.cs_warehouse_sk,
        b.cs_net_paid_inc_tax,
        CASE
            WHEN b.cs_net_paid_inc_tax > a.avg_val THEN 'Above Avg'
            ELSE 'Below Avg'
        END AS payment_category,
        ROW_NUMBER() OVER (PARTITION BY b.c_customer_sk ORDER BY b.cs_net_paid_inc_tax DESC) AS rn_per_customer,
        RANK() OVER (ORDER BY b.cs_net_paid_inc_tax DESC) AS overall_rank
    FROM base b
    CROSS JOIN avg_paid a
    WHERE b.t_meal_time = 'lunch'
      AND EXISTS (
          SELECT 1 FROM catalog_sales cs2
          WHERE cs2.cs_bill_customer_sk = b.c_customer_sk
            AND cs2.cs_net_profit > 1000
      )
) AS lunch
UNION ALL
SELECT *
FROM (
    SELECT
        b.c_customer_sk,
        b.c_birth_month,
        b.cd_gender,
        b.hd_income_band_sk,
        b.t_meal_time,
        b.cs_warehouse_sk,
        b.cs_net_paid_inc_tax,
        CASE
            WHEN b.cs_net_paid_inc_tax > a.avg_val THEN 'Above Avg'
            ELSE 'Below Avg'
        END AS payment_category,
        ROW_NUMBER() OVER (PARTITION BY b.c_customer_sk ORDER BY b.cs_net_paid_inc_tax DESC) AS rn_per_customer,
        RANK() OVER (ORDER BY b.cs_net_paid_inc_tax DESC) AS overall_rank
    FROM base b
    CROSS JOIN avg_paid a
    WHERE b.t_meal_time = 'dinner'
      AND EXISTS (
          SELECT 1 FROM catalog_sales cs2
          WHERE cs2.cs_bill_customer_sk = b.c_customer_sk
            AND cs2.cs_net_profit > 1000
      )
) AS dinner
ORDER BY overall_rank ASC, payment_category DESC
LIMIT 100
